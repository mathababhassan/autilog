// ─── Scheduled notifications ───────────────────────────────────────────
// Time-driven reminders that no document event can trigger. Requires Cloud
// Scheduler (enabled on first deploy of a scheduled function).
//
// — Session reminder: every 15 min, find upcoming sessions starting within
// the next 30 min and remind BOTH the parent and the therapist. The reminder is
// idempotent via the deterministic id `sessionReminder_{sessionId}`, so a
// session appearing in two consecutive windows is reminded only once per party.

const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { notifyParty, nameOf, formatTime } = require("./session_notifications");

const REMINDER_LEAD_MIN = 30;

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
