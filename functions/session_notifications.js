// ─── Session notifications (A2) ──────────────────────────────────────────────
// Notifies on the session lifecycle: booking, reschedule, cancellation, and
// parent-visible notes being added. Sessions are top-level `sessions/{id}` docs.
//
// Direction: booking / reschedule / notes are therapist-driven → notify parent.
// Cancellation is two-way (both sides can cancel today), so `cancelSession`
// writes `cancelledByUid`; the trigger compares it to therapistId/parentId and
// notifies the OTHER party.
//
// Date/time in copy is formatted in Asia/Kuala_Lumpur (UTC+8) — the server runs
// in UTC, so formatting without a zone would show the wrong local time.

const admin = require("firebase-admin");
const { onDocumentCreated, onDocumentUpdated } =
  require("firebase-functions/v2/firestore");
const { createNotification, shouldNotify } = require("./notifications");

const TZ = "Asia/Kuala_Lumpur";

function getDb() {
  return admin.firestore();
}

// "4:00 PM" from a Firestore Timestamp, in app-local time.
function formatTime(ts) {
  if (!ts || typeof ts.toDate !== "function") return "";
  return new Intl.DateTimeFormat("en-US", {
    timeZone: TZ,
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(ts.toDate());
}

// "Wed 25 Jun at 4:00 PM" from a Firestore Timestamp.
function formatWhen(ts) {
  if (!ts || typeof ts.toDate !== "function") return "";
  const date = new Intl.DateTimeFormat("en-GB", {
    timeZone: TZ,
    weekday: "short",
    day: "numeric",
    month: "short",
  }).format(ts.toDate());
  return `${date} at ${formatTime(ts)}`;
}

async function nameOf(db, collection, uid, fallback) {
  if (!uid) return fallback;
  const snap = await db.doc(`${collection}/${uid}`).get();
  return snap.data()?.name || fallback;
}

// Writes a session notification to one recipient, gated by their prefs.
async function notifyParty(db, { role, recipientId, prefsType, id, title, message, sessionId }) {
  const snap = await db.doc(`${role === "parent" ? "parents" : "therapists"}/${recipientId}`).get();
  if (!shouldNotify(role, snap.data(), prefsType)) {
    console.log(`[session] suppressed by prefs: role=${role} recipient=${recipientId} session=${sessionId}`);
    return;
  }
  const { created } = await createNotification(db, {
    role,
    recipientId,
    id,
    type: prefsType,
    title,
    message,
    target: { kind: "session", id: sessionId },
    recipientData: snap.data(),
  });
  console.log(`[session] role=${role} recipient=${recipientId} session=${sessionId} type=${prefsType} created=${created}`);
}

// ── Booking ──────────────────────────────────────────────────────────────────
async function handleSessionCreated(event) {
  const snap = event.data;
  if (!snap) return;
  const s = snap.data();
  const sessionId = event.params.sessionId;
  if (s.status === "cancelled") return; // created already-cancelled: nothing to announce

  try {
    const db = getDb();
    const therapistName = await nameOf(db, "therapists", s.therapistId, "Your therapist");
    await notifyParty(db, {
      role: "parent",
      recipientId: s.parentId,
      prefsType: "sessionBooked",
      id: `sessionBooked_${sessionId}`,
      title: "New session scheduled",
      message: `${therapistName} scheduled a session for ${s.childName || "your child"} on ${formatWhen(s.scheduledAt)}.`,
      sessionId,
    });
  } catch (err) {
    console.error(`[session] booking failed for session=${sessionId}:`, err);
  }
}

// ── Reschedule / cancel / notes ──────────────────────────────────────────────
async function handleSessionUpdated(event) {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  const sessionId = event.params.sessionId;

  try {
    const db = getDb();
    const childName = after.childName || "your child";

    // 1) Cancellation (highest priority) — route to the non-canceller. Only an
    // explicit parent cancel notifies the therapist; therapist-cancel or an
    // unknown/legacy actor defaults to notifying the parent.
    if (before.status !== "cancelled" && after.status === "cancelled") {
      const when = formatWhen(after.scheduledAt);
      const parentCancelled = after.cancelledByUid === after.parentId;

      if (parentCancelled) {
        const parentName = await nameOf(db, "parents", after.parentId, "The parent");
        await notifyParty(db, {
          role: "therapist",
          recipientId: after.therapistId,
          prefsType: "sessionCancelled",
          id: `sessionCancelled_${sessionId}`,
          title: "Session cancelled",
          message: `${parentName} cancelled ${childName}'s session on ${when}.`,
          sessionId,
        });
      } else {
        const therapistName = await nameOf(db, "therapists", after.therapistId, "Your therapist");
        await notifyParty(db, {
          role: "parent",
          recipientId: after.parentId,
          prefsType: "sessionCancelled",
          id: `sessionCancelled_${sessionId}`,
          title: "Session cancelled",
          message: `${therapistName} cancelled ${childName}'s session on ${when}.`,
          sessionId,
        });
      }
      return;
    }

    // 2) Reschedule — scheduledAt moved.
    const beforeMs = before.scheduledAt?.toMillis?.();
    const afterMs = after.scheduledAt?.toMillis?.();
    if (beforeMs && afterMs && beforeMs !== afterMs && after.status !== "cancelled") {
      const therapistName = await nameOf(db, "therapists", after.therapistId, "Your therapist");
      await notifyParty(db, {
        role: "parent",
        recipientId: after.parentId,
        prefsType: "sessionRescheduled",
        id: `sessionRescheduled_${sessionId}_${afterMs}`,
        title: "Session rescheduled",
        message: `${therapistName} moved ${childName}'s session to ${formatWhen(after.scheduledAt)}.`,
        sessionId,
      });
      return;
    }

    // 3) Parent-visible notes added/updated.
    const notesChanged = (after.notes || "") !== (before.notes || "");
    if (notesChanged && (after.notes || "").trim().length > 0) {
      const therapistName = await nameOf(db, "therapists", after.therapistId, "Your therapist");
      const editedMs = after.notesLastEditedAt?.toMillis?.() || "na";
      await notifyParty(db, {
        role: "parent",
        recipientId: after.parentId,
        prefsType: "sessionNotesAdded",
        id: `sessionNotesAdded_${sessionId}_${editedMs}`,
        title: "Session notes added",
        message: `${therapistName} added notes to ${childName}'s session from ${formatWhen(after.scheduledAt)}.`,
        sessionId,
      });
    }
  } catch (err) {
    console.error(`[session] update failed for session=${sessionId}:`, err);
  }
}

module.exports.onSessionCreated = onDocumentCreated(
  { document: "sessions/{sessionId}" },
  handleSessionCreated
);
module.exports.onSessionUpdated = onDocumentUpdated(
  { document: "sessions/{sessionId}" },
  handleSessionUpdated
);

// Shared with scheduled_notifications.js (A3 session reminder).
module.exports.notifyParty = notifyParty;
module.exports.nameOf = nameOf;
module.exports.formatTime = formatTime;
