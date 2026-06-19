// ─── Notification record layer (A0) ──────────────────────────────────────────
// The single writer for in-app notification records. Every notification trigger
// (comments, sessions, scheduled reminders) goes through createNotification so
// there is exactly one place that owns the document shape and, later, push.
//
// Records live in a per-role subcollection, functions-only on create:
//   parents/{uid}/notifications/{notifId}
//   therapists/{uid}/notifications/{notifId}
//
// Document contract (store SEMANTICS, never presentation — the client maps
// `type` → icon/colour):
//   {
//     type:      one of NOTIFICATION_TYPES
//     title:     string   // bold line in the row
//     body:      string   // 2-line message
//     read:      boolean   // starts false; client flips to true
//     createdAt: serverTimestamp
//     target:    null | {  // where a tap should navigate (semantic, not a URL)
//       screen:   'incident'|'positiveMoment'|'dailySummary'|'sessions'|'aiInsights'|'logCreate'
//       childId?: string
//       sourceId?: string  // the log / session id to open
//     }
//   }
//
// Idempotency: Firestore triggers are at-least-once, so callers pass a
// DETERMINISTIC id derived from the source event (e.g. `comment_${commentId}`,
// `dailyLogReminder_${childId}_${yyyymmdd}`). We write with .create(), which
// throws ALREADY_EXISTS on a re-fire — caught here so a retry never duplicates a
// row or resets `read` on a notification the user already opened.

const admin = require("firebase-admin");

const ROLE_COLLECTIONS = {
  parent: "parents",
  therapist: "therapists",
};

const NOTIFICATION_TYPES = new Set([
  "comment",
  "sessionBooked",
  "sessionRescheduled",
  "sessionCancelled",
  "sessionReminder",
  "dailyLogReminder",
  "aiInsight",
]);

// gRPC status code for ALREADY_EXISTS (thrown by DocumentReference.create()).
const ALREADY_EXISTS = 6;

/**
 * Create one in-app notification record (idempotent).
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {Object} params
 * @param {'parent'|'therapist'} params.role     recipient role → collection
 * @param {string} params.recipientId            recipient uid (doc id)
 * @param {string} params.id                     deterministic notification id
 * @param {string} params.type                   one of NOTIFICATION_TYPES
 * @param {string} params.title
 * @param {string} params.body
 * @param {Object|null} [params.target]          tap-routing map (see contract)
 * @returns {Promise<{created: boolean}>}  created=false means a duplicate fire
 */
async function createNotification(db, params) {
  const { role, recipientId, id, type, title, body, target = null } = params;

  const collection = ROLE_COLLECTIONS[role];
  if (!collection) throw new Error(`createNotification: unknown role "${role}"`);
  if (!recipientId) throw new Error("createNotification: recipientId is required");
  if (!id) throw new Error("createNotification: a deterministic id is required");
  if (!NOTIFICATION_TYPES.has(type)) {
    throw new Error(`createNotification: unknown type "${type}"`);
  }

  const ref = db.doc(`${collection}/${recipientId}/notifications/${id}`);

  const payload = {
    type,
    title: title || "",
    body: body || "",
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    target: target || null,
  };

  try {
    await ref.create(payload);
    // ── A5 seam ──────────────────────────────────────────────────────────────
    // When FCM token storage exists, look up the recipient's token(s) and send
    // the push HERE. Every call site gets push for free, with no changes.
    return { created: true };
  } catch (err) {
    if (err.code === ALREADY_EXISTS) return { created: false };
    throw err;
  }
}

module.exports = { createNotification, NOTIFICATION_TYPES };
