// ─── Removal notifications (A8) ──────────────────────────────────────────────
// Notifies a therapist when a patient is removed. We ride the therapist's
// patient-record `status` (set by the deletion flows) rather than an onDelete on
// the child doc — so the record persists (the notification stays deep-linkable)
// and there's no fan-out ambiguity (one therapist per child, per project rule).
//
//   status 'child_deleted'  → childRemoved          (parent deleted the child)
//   status 'parent_removed' → parentAccountRemoved  (parent deleted their account)
//
// childRemoved fires today — `deleteChild` already sets 'child_deleted'.
// parentAccountRemoved is DORMANT until the (unbuilt) delete-account cascade sets
// 'parent_removed' on each patient record: that single field-set is all that's
// needed to light it up — the cascade must SET the status, not hard-delete the
// record. These lifecycle types are ungated (not in any prefs group) → always sent.

const admin = require("firebase-admin");
const { onDocumentUpdated, onDocumentDeleted } =
  require("firebase-functions/v2/firestore");
const { createNotification } = require("./notifications");

const REMOVAL_BY_STATUS = {
  child_deleted: {
    type: "childRemoved",
    title: "Patient removed",
    message: (name) => `${name}'s profile was removed by the parent.`,
  },
  parent_removed: {
    type: "parentAccountRemoved",
    title: "Patient account removed",
    message: (name) => `${name}'s parent deleted their account.`,
  },
};

function getDb() {
  return admin.firestore();
}

async function handlePatientStatusChanged(event) {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  if (before.status === after.status) return;

  const config = REMOVAL_BY_STATUS[after.status];
  if (!config) return; // not a removal transition

  const { therapistId, childId } = event.params;
  try {
    const db = getDb();
    const childName = after.childName || "A patient";
    const { created } = await createNotification(db, {
      role: "therapist",
      recipientId: therapistId,
      id: `${config.type}_${childId}`,
      type: config.type,
      title: config.title,
      message: config.message(childName),
      target: { kind: "patient", id: childId },
    });
    console.log(`[removal] therapist=${therapistId} ${config.type} child=${childId} created=${created}`);
  } catch (err) {
    console.error(`[removal] failed for therapist=${therapistId} child=${childId}:`, err);
  }
}

module.exports.onPatientStatusChanged = onDocumentUpdated(
  { document: "therapists/{therapistId}/patients/{childId}" },
  handlePatientStatusChanged
);

// A parent revoking access DELETES the patient record (not a status change), and
// so does a therapist removing the patient themselves — the same delete from two
// actors. `revokeTherapistAccess` stamps `removedBy:'parent'` just before the
// delete, so we notify only on a parent revocation. A therapist self-removal
// leaves no marker → skipped (they did it). The record is gone, so the target is
// the Patients list rather than the (now-missing) patient.
async function handlePatientRemoved(event) {
  const data = event.data?.data();
  if (!data || data.removedBy !== "parent") return;

  const { therapistId, childId } = event.params;
  try {
    const db = getDb();
    const childName = data.childName || "a patient";
    // Per-revocation stamp keeps the id stable across retries but unique across
    // separate revocations (re-link then re-revoke re-notifies).
    const revokedMs = data.removedAt?.toMillis?.() || "x";
    const { created } = await createNotification(db, {
      role: "therapist",
      recipientId: therapistId,
      id: `accessRevoked_${childId}_${revokedMs}`,
      type: "accessRevoked",
      title: "Access revoked",
      message: `Your access to ${childName} was revoked by the parent.`,
      target: { kind: "patient" },
    });
    console.log(`[removal] therapist=${therapistId} accessRevoked child=${childId} created=${created}`);
  } catch (err) {
    console.error(`[removal] accessRevoked failed for therapist=${therapistId} child=${childId}:`, err);
  }
}

module.exports.onPatientRemoved = onDocumentDeleted(
  { document: "therapists/{therapistId}/patients/{childId}" },
  handlePatientRemoved
);
