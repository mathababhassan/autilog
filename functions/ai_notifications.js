// ─── AI insights notifications (A6) ──────────────────────────────────────────
// Notifies the parent + linked therapist(s) when a child's weekly AI insights
// are ready. Two entry points share notifyInsightsReady():
//   • onAiInsightsReady — event-driven, fires once when insights first unlock
//     (isUnlocked false→true on parents/{p}/children/{c}/aiInsights/current).
//   • the weekly scheduled refresh in scheduled_notifications.js.

const admin = require("firebase-admin");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { createNotification, shouldNotify } = require("./notifications");

function getDb() {
  return admin.firestore();
}

// Notify the parent and every linked therapist that a child's insights are ready.
// `idSuffix` makes the notification id unique per occasion (unlock vs each week).
async function notifyInsightsReady(db, { parentId, childId, idSuffix }) {
  const childSnap = await db.doc(`parents/${parentId}/children/${childId}`).get();
  const childName = childSnap.data()?.name || "your child";
  const title = "AI insights ready";
  const message = `This week's AI insights for ${childName} are ready to view.`;
  const id = `aiInsight_${idSuffix}`;

  // Parent → AI Insights screen.
  try {
    const parentSnap = await db.doc(`parents/${parentId}`).get();
    if (shouldNotify("parent", parentSnap.data(), "aiInsight")) {
      await createNotification(db, {
        role: "parent",
        recipientId: parentId,
        id,
        type: "aiInsight",
        title,
        message,
        target: { kind: "aiInsights", childId },
      });
    }
  } catch (err) {
    console.error(`[aiInsight] parent notify failed for child=${childId}:`, err);
  }

  // Linked therapists → Patient Details (needs parentId + childId).
  const linksSnap = await db
    .collection(`parents/${parentId}/children/${childId}/linkedTherapists`)
    .get();
  for (const linkDoc of linksSnap.docs) {
    const therapistId = linkDoc.id;
    try {
      const therapistSnap = await db.doc(`therapists/${therapistId}`).get();
      if (!shouldNotify("therapist", therapistSnap.data(), "aiInsight")) continue;
      await createNotification(db, {
        role: "therapist",
        recipientId: therapistId,
        id,
        type: "aiInsight",
        title,
        message,
        target: { kind: "aiInsights", childId, parentId },
      });
    } catch (err) {
      console.error(`[aiInsight] failed for therapist=${therapistId} child=${childId}:`, err);
    }
  }
}

// Fire once when insights flip from not-ready to ready.
async function handleAiInsightsWritten(event) {
  const before = event.data?.before;
  const after = event.data?.after;
  const wasUnlocked = before?.exists && before.data().isUnlocked === true;
  const isUnlocked = after?.exists && after.data().isUnlocked === true;
  if (wasUnlocked || !isUnlocked) return; // only the false→true transition

  const { parentId, childId } = event.params;
  try {
    await notifyInsightsReady(getDb(), { parentId, childId, idSuffix: `unlock_${childId}` });
    console.log(`[aiInsight] unlock notified parent=${parentId} child=${childId}`);
  } catch (err) {
    console.error(`[aiInsight] unlock failed for child=${childId}:`, err);
  }
}

module.exports.notifyInsightsReady = notifyInsightsReady;
module.exports.onAiInsightsReady = onDocumentWritten(
  { document: "parents/{parentId}/children/{childId}/aiInsights/current" },
  handleAiInsightsWritten
);
