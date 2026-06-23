// ─── Log notifications (A5) ──────────────────────────────────────────────────
// When a parent creates a log, notify the child's linked therapist(s). An
// incident with high severity escalates to the always-on highSeverityIncident
// alert (bypasses the mute, safety); otherwise — and for daily summaries /
// positive moments — it's an ordinary logAdded alert (gated by patientActivity).
//
// Logs live at parents/{parentId}/children/{childId}/{logCollection}/{logId}.
// Firestore can't wildcard a collection name → one handler per collection.

const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { createNotification, shouldNotify } = require("./notifications");

const HIGH_SEVERITY_MIN = 4; // behaviorSeverity >= this escalates (1–5 scale)

const LOG_LABELS = {
  dailySummaries: "daily summary",
  incidents: "behavioral incident",
  positiveMoments: "positive moment",
};
const TARGET_KIND = {
  dailySummaries: "dailySummary",
  incidents: "incident",
  positiveMoments: "positiveMoment",
};

function getDb() {
  return admin.firestore();
}

async function handleLogCreated(logCollection, event) {
  const snap = event.data;
  if (!snap) return;

  const log = snap.data();
  const { parentId, childId, logId } = event.params;

  try {
    const db = getDb();

    // Linked therapists = fan-out recipients. None → nothing to do (skip reads).
    const linksSnap = await db
      .collection(`parents/${parentId}/children/${childId}/linkedTherapists`)
      .get();
    if (linksSnap.empty) return;

    const childSnap = await db.doc(`parents/${parentId}/children/${childId}`).get();
    const childName = childSnap.data()?.name || "the child";
    const parentSnap = await db.doc(`parents/${parentId}`).get();
    const parentName = parentSnap.data()?.name || "A parent";

    // High-severity incidents escalate to the always-on alert.
    const isHighSeverity =
      logCollection === "incidents" &&
      typeof log.behaviorSeverity === "number" &&
      log.behaviorSeverity >= HIGH_SEVERITY_MIN;

    const type = isHighSeverity ? "highSeverityIncident" : "logAdded";
    const title = isHighSeverity ? "High-severity incident" : "New log added";
    const message = isHighSeverity
      ? `A high-severity incident was logged for ${childName}.`
      : `${parentName} logged a ${LOG_LABELS[logCollection] || "log"} for ${childName}.`;
    const target = { kind: TARGET_KIND[logCollection], id: logId, childId, parentId };

    for (const linkDoc of linksSnap.docs) {
      const therapistId = linkDoc.id;
      try {
        const therapistSnap = await db.doc(`therapists/${therapistId}`).get();
        if (!shouldNotify("therapist", therapistSnap.data(), type)) {
          console.log(`[log] suppressed by prefs: therapist=${therapistId} ${type} log=${logId}`);
          continue;
        }
        const { created } = await createNotification(db, {
          role: "therapist",
          recipientId: therapistId,
          id: `${type}_${logId}`,
          type,
          title,
          message,
          target,
          recipientData: therapistSnap.data(),
        });
        console.log(`[log] therapist=${therapistId} ${type} log=${logId} created=${created}`);
      } catch (err) {
        console.error(`[log] failed for therapist=${therapistId} log=${logId}:`, err);
      }
    }
  } catch (err) {
    console.error(`[log] failed for log=${logId}:`, err);
  }
}

function triggerFor(logCollection) {
  return onDocumentCreated(
    { document: `parents/{parentId}/children/{childId}/${logCollection}/{logId}` },
    (event) => handleLogCreated(logCollection, event)
  );
}

module.exports.onIncidentLogged = triggerFor("incidents");
module.exports.onPositiveMomentLogged = triggerFor("positiveMoments");
module.exports.onDailySummaryLogged = triggerFor("dailySummaries");
