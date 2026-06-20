// ─── Notification record layer (A0) ──────────────────────────────────────────
// The single writer for in-app notification records. Every notification trigger
// (comments, sessions, log alerts, AI insights, scheduled reminders, lifecycle
// deletes) goes through createNotification so there is exactly one place that
// owns the document shape and, later, push.
//
// Records live in a per-role subcollection, functions-only on create:
//   parents/{uid}/notifications/{notifId}
//   therapists/{uid}/notifications/{notifId}
//
// Document contract (store SEMANTICS, never presentation — the client maps
// `type` → icon/colour). Field names track the design catalogue so the inbox UI
// and the backend converge without coordination:
//   {
//     type:      one of NOTIFICATION_TYPES
//     title:     string   // bold line in the row
//     message:   string   // 2-line body text
//     read:      boolean   // starts false; client flips to true
//     createdAt: serverTimestamp
//     target:    null | {  // where a tap should navigate (semantic, not a URL)
//       kind:     'session'|'incident'|'positiveMoment'|'dailySummary'
//               | 'aiInsights'|'logCreate'|'patient'|'linkRequest'
//       id?:      string   // primary resource id (sessionId, logId, childId, requestId)
//       childId?: string   // for nested log / aiInsights paths
//       parentId?: string  // for therapist deep-links into a parent's nested data
//     }
//   }
//
// Idempotency: Firestore triggers are at-least-once, so callers pass a
// DETERMINISTIC id derived from the source event (e.g. `comment_${commentId}`,
// `dailyLogReminder_${childId}_${yyyymmdd}`). We write with .create(), which
// throws ALREADY_EXISTS on a re-fire — caught here so a retry never duplicates a
// row or resets `read` on a notification the user already opened.
//
// Preferences: recipients are gated by shouldNotify() BEFORE this is called; a
// suppressed type writes no record and sends no push. Both parents (P-37) and
// therapists (T-36) have a `notificationPrefs` map. High-severity incident
// alerts are LOCKED ON and ignore prefs (safety).

const admin = require("firebase-admin");

const ROLE_COLLECTIONS = {
  parent: "parents",
  therapist: "therapists",
};

const NOTIFICATION_TYPES = new Set([
  // parent-facing + shared with therapist
  "sessionBooked",
  "sessionRescheduled",
  "sessionCancelled",
  "sessionReminder",
  "sessionNotesAdded",
  "comment",
  "aiInsight",
  "dailyLogReminder",
  // therapist-facing
  "linkRequest",
  "logAdded",
  "highSeverityIncident",
  // lifecycle (recipient = therapist)
  "childRemoved",
  "parentAccountRemoved",
]);

// Allowed values for `target.kind` (the tap-routing destination) and the only
// keys a `target` may contain. Validated on write so a stale field name (e.g. a
// leftover `screen`/`sourceId`) or unknown kind fails loudly here instead of
// silently producing a dead-end deep-link in the inbox.
const TARGET_KINDS = new Set([
  "session",
  "incident",
  "positiveMoment",
  "dailySummary",
  "aiInsights",
  "logCreate",
  "patient",
  "linkRequest",
]);
const TARGET_KEYS = new Set(["kind", "id", "childId", "parentId"]);

// Types that ALWAYS send and ignore every preference (safety). T-36 locks the
// high-severity alert toggle ON; this enforces it server-side too.
const ALWAYS_SEND = new Set(["highSeverityIncident"]);

// Notification type → the preference toggle that gates it, per recipient role.
// A type absent from a role's map is ungated for that role (e.g. lifecycle
// deletes). Pref-group keys must match the field names the Settings screens
// write into `notificationPrefs`.
const PARENT_PREF_GROUP = {
  sessionBooked: "sessionUpdates",
  sessionRescheduled: "sessionUpdates",
  sessionCancelled: "sessionUpdates",
  sessionReminder: "sessionUpdates",
  sessionNotesAdded: "sessionUpdates",
  comment: "therapistComments",
  dailyLogReminder: "dailyLogReminders",
  aiInsight: "weeklyAiInsights",
};
const THERAPIST_PREF_GROUP = {
  linkRequest: "patientRequests",
  logAdded: "patientActivity",
  comment: "patientActivity",
  sessionReminder: "sessionUpdates",
  sessionCancelled: "sessionUpdates",
  aiInsight: "weeklyAiInsights",
  // highSeverityIncident → ALWAYS_SEND, intentionally not gated here.
};

// gRPC status code for ALREADY_EXISTS (thrown by DocumentReference.create()).
const ALREADY_EXISTS = 6;

/**
 * Whether a notification of `type` should be sent to this recipient, per their
 * preferences. Gates both the record and the push (a `false` toggle means the
 * recipient sees nothing). Every toggle defaults ON, so only an explicit `false`
 * suppresses. High-severity alerts always send.
 *
 * @param {'parent'|'therapist'} role
 * @param {Object|undefined} recipientData  the parent/therapist doc data
 * @param {string} type
 * @returns {boolean}
 */
function shouldNotify(role, recipientData, type) {
  if (ALWAYS_SEND.has(type)) return true; // safety override

  const groupMap =
    role === "parent" ? PARENT_PREF_GROUP
    : role === "therapist" ? THERAPIST_PREF_GROUP
    : null;
  if (!groupMap) return true;

  const group = groupMap[type];
  if (!group) return true; // ungated type for this role

  const prefs = (recipientData && recipientData.notificationPrefs) || {};
  return prefs[group] !== false; // default ON; only an explicit false suppresses
}

/**
 * Validate a tap-routing target. Null/undefined is allowed (no deep-link).
 * A non-null target must be a plain object with a known `kind` and only the
 * permitted string keys — anything else throws.
 *
 * @param {Object|null|undefined} target
 */
function validateTarget(target) {
  if (target == null) return;
  if (typeof target !== "object" || Array.isArray(target)) {
    throw new Error("createNotification: target must be a plain object or null");
  }
  if (!TARGET_KINDS.has(target.kind)) {
    throw new Error(`createNotification: target.kind "${target.kind}" is not a known kind`);
  }
  for (const key of Object.keys(target)) {
    if (!TARGET_KEYS.has(key)) {
      throw new Error(`createNotification: unexpected target key "${key}"`);
    }
  }
  for (const key of ["id", "childId", "parentId"]) {
    if (target[key] != null && typeof target[key] !== "string") {
      throw new Error(`createNotification: target.${key} must be a string`);
    }
  }
}

/**
 * Create one in-app notification record (idempotent). Caller is responsible for
 * checking shouldNotify() first for the recipient (both roles are gated).
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {Object} params
 * @param {'parent'|'therapist'} params.role     recipient role → collection
 * @param {string} params.recipientId            recipient uid (doc id)
 * @param {string} params.id                     deterministic notification id
 * @param {string} params.type                   one of NOTIFICATION_TYPES
 * @param {string} params.title
 * @param {string} params.message
 * @param {Object|null} [params.target]          tap-routing map (see contract)
 * @returns {Promise<{created: boolean}>}  created=false means a duplicate fire
 */
async function createNotification(db, params) {
  const { role, recipientId, id, type, title, message, target = null } = params;

  const collection = ROLE_COLLECTIONS[role];
  if (!collection) throw new Error(`createNotification: unknown role "${role}"`);
  if (!recipientId) throw new Error("createNotification: recipientId is required");
  if (!id) throw new Error("createNotification: a deterministic id is required");
  if (!NOTIFICATION_TYPES.has(type)) {
    throw new Error(`createNotification: unknown type "${type}"`);
  }
  validateTarget(target);

  const ref = db.doc(`${collection}/${recipientId}/notifications/${id}`);

  const payload = {
    type,
    title: title || "",
    message: message || "",
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    target: target || null,
  };

  try {
    await ref.create(payload);
    // ── A9 (push) seam ─────────────────────────────────────────────────────────
    // When FCM token storage exists, look up the recipient's token(s) and send
    // the push HERE. Every call site gets push for free, with no changes.
    return { created: true };
  } catch (err) {
    if (err.code === ALREADY_EXISTS) return { created: false };
    throw err;
  }
}

module.exports = { createNotification, shouldNotify, NOTIFICATION_TYPES, TARGET_KINDS };
