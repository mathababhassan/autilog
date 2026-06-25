// ─── Comment notifications (A1) ──────────────────────────────────────────────
// When a comment is created on a log, notify the OTHER party. A1 ships the
// therapist→parent direction only (therapist comments already exist in the app);
// the parent→therapist branch is deferred until the parent comment UI exists.
//
// Comments live at:
//   parents/{parentId}/children/{childId}/{logCollection}/{logId}/comments/{commentId}
// where logCollection ∈ dailySummaries | incidents | positiveMoments. Firestore
// triggers can't wildcard a collection name, so one shared handler is registered
// once per collection.
//
// Author inference (backend-pure, see decision): a therapist-authored comment
// carries `therapistId`. Parent-authored comments (future) must carry
// `authorRole: 'parent'` + `authorName`; until then they're ignored here.

const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { createNotification, shouldNotify } = require("./notifications");

function getDb() {
  return admin.firestore();
}

const LOG_LABELS = {
  dailySummaries: "daily summary",
  incidents: "incident log",
  positiveMoments: "positive moment",
};

// logCollection → the target.kind the inbox uses to deep-link the log detail.
const TARGET_KIND = {
  dailySummaries: "dailySummary",
  incidents: "incident",
  positiveMoments: "positiveMoment",
};

async function handleCommentCreated(logCollection, event) {
  const snap = event.data;
  if (!snap) return;

  const comment = snap.data();
  const { parentId, childId, logId, commentId } = event.params;

  // A1: therapist→parent only. A therapist comment carries `therapistId`.
  if (!comment.therapistId) return; // parent-authored (future) — ignored for now

  try {
    const db = getDb();

    // Gate on the parent's notification preferences.
    const parentSnap = await db.doc(`parents/${parentId}`).get();
    if (!shouldNotify("parent", parentSnap.data(), "comment")) {
      console.log(`[comment] suppressed by prefs: parent=${parentId} comment=${commentId}`);
      return;
    }

    const childSnap = await db.doc(`parents/${parentId}/children/${childId}`).get();
    const childName = childSnap.data()?.name || "your child";

    const rawName = comment.therapistName || "Your therapist";
    const authorName = rawName.startsWith("Dr.") ? rawName : `Dr. ${rawName}`;
    const logLabel = LOG_LABELS[logCollection] || "log";

    const { created } = await createNotification(db, {
      role: "parent",
      recipientId: parentId,
      id: `comment_${commentId}`,
      type: "comment",
      title: `New comment from ${authorName}`,
      message: `${authorName} commented on ${childName}'s ${logLabel}.`,
      target: {
        kind: TARGET_KIND[logCollection],
        id: logId,
        childId,
        parentId,
      },
      recipientData: parentSnap.data(),
    });
    console.log(`[comment] parent=${parentId} comment=${commentId} created=${created}`);
  } catch (err) {
    console.error(`[comment] failed for comment=${commentId}:`, err);
  }
}

function triggerFor(logCollection) {
  return onDocumentCreated(
    {
      document: `parents/{parentId}/children/{childId}/${logCollection}/{logId}/comments/{commentId}`,
    },
    (event) => handleCommentCreated(logCollection, event)
  );
}

module.exports.onDailySummaryCommentCreated = triggerFor("dailySummaries");
module.exports.onIncidentCommentCreated = triggerFor("incidents");
module.exports.onPositiveMomentCommentCreated = triggerFor("positiveMoments");
