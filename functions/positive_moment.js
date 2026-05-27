const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } =
  require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

const ALLOWED_SETTINGS = new Set([
  "Home",
  "School",
  "Public Place",
  "Social Visit",
  "Therapy Session",
  "Other",
]);

const ALLOWED_BEHAVIOR_TYPES = new Set([
  "Social Interaction",
  "Communication",
  "Self-Regulation",
  "Cooperation",
  "New Skill",
  "Other",
]);

function getDb() {
  return admin.firestore();
}

function summarizeText(text, maxLen = 120) {
  if (!text || typeof text !== "string") return "";
  const trimmed = text.trim();
  if (trimmed.length <= maxLen) return trimmed;
  return `${trimmed.slice(0, maxLen - 1)}…`;
}

function buildActivityLog(momentId, data) {
  const behaviorTypes = Array.isArray(data.behaviorTypes) ? data.behaviorTypes : [];
  const detailParts = [
    `Setting: ${data.setting || "—"}`,
    behaviorTypes.length ? `Type: ${behaviorTypes.join(", ")}` : null,
    data.positiveBehaviorRating
      ? `Rating: ${data.positiveBehaviorRating}/5`
      : null,
  ].filter(Boolean);

  return {
    type: "positiveMoment",
    sourceCollection: "positiveMoments",
    sourceId: momentId,
    title: "Positive Moment",
    summary: summarizeText(data.behaviorDescription),
    detail: detailParts.join(" · "),
    date: data.date,
    time: data.time,
    setting: data.setting || "",
    behaviorTypes,
    positiveBehaviorRating: data.positiveBehaviorRating || 0,
    effectiveness: data.effectiveness || 0,
    videoUrl: data.videoUrl || null,
    createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function deleteVideoIfPresent(videoUrl) {
  if (!videoUrl || typeof videoUrl !== "string") return;
  try {
    const bucket = admin.storage().bucket();
    const file = bucket.file(decodeStoragePath(videoUrl));
    await file.delete({ ignoreNotFound: true });
  } catch (err) {
    console.warn("Could not delete positive moment video:", err.message);
  }
}

function decodeStoragePath(videoUrl) {
  const marker = "/o/";
  const idx = videoUrl.indexOf(marker);
  if (idx === -1) return "";
  const encoded = videoUrl.substring(idx + marker.length).split("?")[0];
  return decodeURIComponent(encoded);
}

async function decrementChildStats(parentId, childId) {
  const childRef = getDb().doc(`parents/${parentId}/children/${childId}`);
  await getDb().runTransaction(async (tx) => {
    const snap = await tx.get(childRef);
    const current = snap.data()?.stats?.positiveMomentsCount ?? 0;
    tx.set(
      childRef,
      {
        stats: {
          positiveMomentsCount: Math.max(0, current - 1),
        },
      },
      { merge: true }
    );
  });
}

async function syncTherapistFeed(parentId, childId, momentId, data, action) {
  const childSnap = await getDb().doc(`parents/${parentId}/children/${childId}`).get();
  const child = childSnap.data() || {};
  const therapistIds = [];

  if (child.linkedTherapistId) therapistIds.push(child.linkedTherapistId);
  if (Array.isArray(child.therapists)) {
    for (const id of child.therapists) {
      if (id && !therapistIds.includes(id)) therapistIds.push(id);
    }
  }

  if (!therapistIds.length) return;

  const feedPayload =
    action === "delete"
      ? null
      : {
          type: "positiveMoment",
          momentId,
          parentId,
          childId,
          childName: child.name || "",
          summary: summarizeText(data.behaviorDescription, 80),
          setting: data.setting || "",
          positiveBehaviorRating: data.positiveBehaviorRating || 0,
          date: data.date,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

  const batch = getDb().batch();
  for (const therapistId of therapistIds) {
    const ref = getDb().doc(
      `therapists/${therapistId}/patients/${childId}/feed/${momentId}`
    );
    if (action === "delete") {
      batch.delete(ref);
    } else {
      batch.set(ref, feedPayload, { merge: true });
    }
  }
  await batch.commit();
}

function validatePositiveMomentData(data) {
  if (!data || typeof data !== "object") return false;

  const required = [
    "date",
    "time",
    "antecedentDescription",
    "setting",
    "behaviorDescription",
    "behaviorTypes",
    "positiveBehaviorRating",
    "consequenceDescription",
    "effectiveness",
    "createdAt",
    "updatedAt",
  ];
  for (const key of required) {
    if (!(key in data)) return false;
  }

  if (typeof data.antecedentDescription !== "string") return false;
  if (data.antecedentDescription.trim().length === 0) return false;
  if (data.antecedentDescription.length > 4000) return false;

  if (typeof data.setting !== "string" || !ALLOWED_SETTINGS.has(data.setting)) {
    return false;
  }

  if (typeof data.behaviorDescription !== "string") return false;
  if (data.behaviorDescription.trim().length === 0) return false;
  if (data.behaviorDescription.length > 4000) return false;

  if (!Array.isArray(data.behaviorTypes) || data.behaviorTypes.length === 0) {
    return false;
  }
  for (const t of data.behaviorTypes) {
    if (typeof t !== "string" || !ALLOWED_BEHAVIOR_TYPES.has(t)) return false;
  }

  if (
    typeof data.positiveBehaviorRating !== "number" ||
    data.positiveBehaviorRating < 1 ||
    data.positiveBehaviorRating > 5
  ) {
    return false;
  }

  if (typeof data.consequenceDescription !== "string") return false;
  if (data.consequenceDescription.trim().length === 0) return false;

  if (
    typeof data.effectiveness !== "number" ||
    data.effectiveness < 1 ||
    data.effectiveness > 5
  ) {
    return false;
  }

  if (typeof data.time !== "number" || data.time < 0 || data.time > 1439) {
    return false;
  }

  if (data.videoUrl != null && typeof data.videoUrl !== "string") return false;

  return true;
}

const positiveMomentTriggerOpts = {
  document: "parents/{parentId}/children/{childId}/positiveMoments/{momentId}",
};

exports.onPositiveMomentCreated = onDocumentCreated(
  positiveMomentTriggerOpts,
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { parentId, childId, momentId } = event.params;

    if (!validatePositiveMomentData(data)) {
      console.error("Invalid positive moment payload", { parentId, childId, momentId });
      return;
    }

    const db = getDb();
    const activityRef = db.doc(
      `parents/${parentId}/children/${childId}/activityLogs/${momentId}`
    );

    await db.runTransaction(async (tx) => {
      tx.set(activityRef, buildActivityLog(momentId, data));
      tx.set(
        db.doc(`parents/${parentId}/children/${childId}`),
        {
          stats: {
            positiveMomentsCount: admin.firestore.FieldValue.increment(1),
            lastPositiveMomentAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );
    });

    await syncTherapistFeed(parentId, childId, momentId, data, "upsert");
  }
);

exports.onPositiveMomentUpdated = onDocumentUpdated(
  positiveMomentTriggerOpts,
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const data = after.data();
    const { parentId, childId, momentId } = event.params;

    if (!validatePositiveMomentData(data)) {
      console.error("Invalid positive moment update", { parentId, childId, momentId });
      return;
    }

    const activityRef = getDb().doc(
      `parents/${parentId}/children/${childId}/activityLogs/${momentId}`
    );
    await activityRef.set(buildActivityLog(momentId, data), { merge: true });
    await syncTherapistFeed(parentId, childId, momentId, data, "upsert");
  }
);

exports.onPositiveMomentDeleted = onDocumentDeleted(
  positiveMomentTriggerOpts,
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { parentId, childId, momentId } = event.params;
    const db = getDb();

    await db
      .doc(`parents/${parentId}/children/${childId}/activityLogs/${momentId}`)
      .delete();

    await decrementChildStats(parentId, childId);
    await deleteVideoIfPresent(data.videoUrl);
    await syncTherapistFeed(parentId, childId, momentId, data, "delete");
  }
);

module.exports.validatePositiveMomentData = validatePositiveMomentData;
module.exports.ALLOWED_SETTINGS = ALLOWED_SETTINGS;
module.exports.ALLOWED_BEHAVIOR_TYPES = ALLOWED_BEHAVIOR_TYPES;
