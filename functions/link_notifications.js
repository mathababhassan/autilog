// ─── Link request notifications (A7) ─────────────────────────────────────────
// When a parent creates a patient link request, notify the target therapist
// in-app. The active path writes to the top-level `linkRequests` collection
// (the Cloud Function sendLinkRequest is orphaned). The request targets a
// therapist by EMAIL, so we look up their account; if they aren't a registered
// therapist yet there's no in-app account to notify (they'd get nothing until
// they sign up). `childName`/`parentName` are denormalized by one client path
// but not the other, so we fall back to reading the docs (admin bypasses rules).

const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { createNotification, shouldNotify } = require("./notifications");

function getDb() {
  return admin.firestore();
}

async function nameFromDoc(ref, fallback) {
  const snap = await ref.get();
  return snap.data()?.name || fallback;
}

async function handleLinkRequestCreated(event) {
  const snap = event.data;
  if (!snap) return;
  const req = snap.data();
  const requestId = event.params.requestId;

  if (req.status !== "pending" || !req.therapistEmail) return;

  try {
    const db = getDb();

    const therapistQuery = await db
      .collection("therapists")
      .where("email", "==", req.therapistEmail)
      .limit(1)
      .get();
    if (therapistQuery.empty) {
      console.log(`[linkRequest] no registered therapist for ${req.therapistEmail} (request=${requestId})`);
      return;
    }
    const therapistDoc = therapistQuery.docs[0];
    const therapistId = therapistDoc.id;

    if (!shouldNotify("therapist", therapistDoc.data(), "linkRequest")) {
      console.log(`[linkRequest] suppressed by prefs: therapist=${therapistId} request=${requestId}`);
      return;
    }

    const parentName =
      req.parentName || (await nameFromDoc(db.doc(`parents/${req.parentId}`), "A parent"));
    const childName =
      req.childName ||
      (await nameFromDoc(db.doc(`parents/${req.parentId}/children/${req.childId}`), "their child"));

    const { created } = await createNotification(db, {
      role: "therapist",
      recipientId: therapistId,
      id: `linkRequest_${requestId}`,
      type: "linkRequest",
      title: "New patient link request",
      message: `${parentName} wants to link ${childName} to your caseload.`,
      target: { kind: "linkRequest", id: requestId },
      recipientData: therapistDoc.data(),
    });
    console.log(`[linkRequest] therapist=${therapistId} request=${requestId} created=${created}`);
  } catch (err) {
    console.error(`[linkRequest] failed for request=${requestId}:`, err);
  }
}

module.exports.onLinkRequestCreated = onDocumentCreated(
  { document: "linkRequests/{requestId}" },
  handleLinkRequestCreated
);
