// ─── Scheduled notifications ───────────────────────────────────────────
// Time-driven reminders that no document event can trigger. Requires Cloud
// Scheduler (enabled on first deploy of a scheduled function).
//
// — Session reminder: every 15 min, find upcoming sessions starting within
// the next 30 min and remind BOTH the parent and the therapist. The reminder is
// idempotent via the deterministic id `sessionReminder_{sessionId}`, so a
// session appearing in two consecutive windows is reminded only once per party.
//
// — Daily-log reminder: once a day at 8 PM local time, nudge each parent who
// hasn't logged a daily summary for a child today. Idempotent via the id
// `dailyLogReminder_{childId}_{yyyymmdd}`.

const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { notifyParty, nameOf, formatTime } = require("./session_notifications");
const { notifyInsightsReady } = require("./ai_notifications");
const { createNotification, shouldNotify } = require("./notifications");

const REMINDER_LEAD_MIN = 30;

// App-local timezone (Asia/Kuala_Lumpur, no DST). This offset bounds "today" and
// MUST stay in sync with the `timeZone` of the onDailyLogReminder schedule below
// — change both together, or the cutoff and the day window will disagree.
const LOCAL_TZ_OFFSET_HOURS = 8;

function getDb() {
  return admin.firestore();
}

async function handleSessionReminders() {
  const db = getDb();
  const now = admin.firestore.Timestamp.now();
  const windowEnd = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + REMINDER_LEAD_MIN * 60 * 1000
  );

  const snap = await db
    .collection("sessions")
    .where("status", "==", "upcoming")
    .where("scheduledAt", ">=", now)
    .where("scheduledAt", "<=", windowEnd)
    .get();

  for (const doc of snap.docs) {
    const s = doc.data();
    const sessionId = doc.id;
    try {
      const therapistName = await nameOf(db, "therapists", s.therapistId, "your therapist");
      const childName = s.childName || "your child";
      const time = formatTime(s.scheduledAt);
      const id = `sessionReminder_${sessionId}`;

      await notifyParty(db, {
        role: "parent",
        recipientId: s.parentId,
        prefsType: "sessionReminder",
        id,
        title: "Session reminder",
        message: `${childName}'s session with ${therapistName} starts at ${time}.`,
        sessionId,
      });

      await notifyParty(db, {
        role: "therapist",
        recipientId: s.therapistId,
        prefsType: "sessionReminder",
        id,
        title: "Session reminder",
        message: `Your session with ${childName} starts at ${time}.`,
        sessionId,
      });
    } catch (err) {
      console.error(`[reminder] failed for session=${sessionId}:`, err);
    }
  }

  console.log(`[reminder] processed ${snap.size} upcoming session(s) in window`);
}

module.exports.onSessionReminder = onSchedule(
  { schedule: "every 15 minutes" },
  handleSessionReminders
);

// ── Daily-log reminder ───────────────────────────────────────────────────────

// Start/end Timestamps of "today" in app-local time, plus a yyyymmdd stamp for
// the idempotency key.
function localDayBounds(now = new Date()) {
  const offsetMs = LOCAL_TZ_OFFSET_HOURS * 60 * 60 * 1000;
  const local = new Date(now.getTime() + offsetMs);
  const y = local.getUTCFullYear();
  const m = local.getUTCMonth();
  const d = local.getUTCDate();
  const startMs = Date.UTC(y, m, d) - offsetMs; // local midnight, expressed in UTC
  return {
    startTs: admin.firestore.Timestamp.fromMillis(startMs),
    endTs: admin.firestore.Timestamp.fromMillis(startMs + 24 * 60 * 60 * 1000),
    yyyymmdd: `${y}${String(m + 1).padStart(2, "0")}${String(d).padStart(2, "0")}`,
  };
}

async function handleDailyLogReminders() {
  const db = getDb();
  const { startTs, endTs, yyyymmdd } = localDayBounds();

  let parents;
  try {
    parents = await db.collection("parents").get();
  } catch (err) {
    console.error("[dailyLog] failed to list parents:", err);
    return;
  }
  let reminded = 0;

  for (const parentDoc of parents.docs) {
    const parentId = parentDoc.id;
    // Gate once per parent — a muted parent skips all child reads.
    if (!shouldNotify("parent", parentDoc.data(), "dailyLogReminder")) continue;

    let children;
    try {
      children = await db.collection(`parents/${parentId}/children`).get();
    } catch (err) {
      console.error(`[dailyLog] failed to list children for parent=${parentId}:`, err);
      continue;
    }
    for (const childDoc of children.docs) {
      const childId = childDoc.id;
      const childName = childDoc.data()?.name || "your child";
      try {
        const logged = await db
          .collection(`parents/${parentId}/children/${childId}/dailySummaries`)
          .where("date", ">=", startTs)
          .where("date", "<", endTs)
          .limit(1)
          .get();
        if (!logged.empty) continue; // already logged today

        const { created } = await createNotification(db, {
          role: "parent",
          recipientId: parentId,
          id: `dailyLogReminder_${childId}_${yyyymmdd}`,
          type: "dailyLogReminder",
          title: "Daily log reminder",
          message: `You haven't logged a daily summary for ${childName} yet.`,
          target: { kind: "logCreate", childId },
        });
        if (created) reminded += 1;
      } catch (err) {
        console.error(`[dailyLog] failed for parent=${parentId} child=${childId}:`, err);
      }
    }
  }

  console.log(`[dailyLog] sent ${reminded} reminder(s) for ${yyyymmdd}`);
}

module.exports.onDailyLogReminder = onSchedule(
  { schedule: "0 20 * * *", timeZone: "Asia/Kuala_Lumpur" },
  handleDailyLogReminders
);

// ── Weekly AI-insights refresh ───────────────────────────────────────────────
// Monday 9 AM local: nudge parents + therapists that this week's insights are
// ready to review, for every child whose insights are unlocked. The run date
// stamps the idempotency key so it fires at most once per child per week.

async function handleWeeklyAiInsights() {
  const db = getDb();
  const { yyyymmdd } = localDayBounds();

  let parents;
  try {
    parents = await db.collection("parents").get();
  } catch (err) {
    console.error("[weeklyAi] failed to list parents:", err);
    return;
  }

  let sent = 0;
  for (const parentDoc of parents.docs) {
    const parentId = parentDoc.id;

    let children;
    try {
      children = await db.collection(`parents/${parentId}/children`).get();
    } catch (err) {
      console.error(`[weeklyAi] failed to list children for parent=${parentId}:`, err);
      continue;
    }

    for (const childDoc of children.docs) {
      const childId = childDoc.id;
      try {
        const insights = await db
          .doc(`parents/${parentId}/children/${childId}/aiInsights/current`)
          .get();
        if (insights.data()?.isUnlocked !== true) continue; // not ready yet

        await notifyInsightsReady(db, {
          parentId,
          childId,
          idSuffix: `weekly_${childId}_${yyyymmdd}`,
        });
        sent += 1;
      } catch (err) {
        console.error(`[weeklyAi] failed for parent=${parentId} child=${childId}:`, err);
      }
    }
  }

  console.log(`[weeklyAi] processed ${sent} child(ren) for ${yyyymmdd}`);
}

module.exports.onWeeklyAiInsights = onSchedule(
  { schedule: "0 9 * * 1", timeZone: "Asia/Kuala_Lumpur" },
  handleWeeklyAiInsights
);
