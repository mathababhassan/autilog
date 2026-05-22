const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { onInit } = require("firebase-functions/v2/core");

let db;

onInit(async () => {
    if (!admin.apps.length) {
        admin.initializeApp();
    }
    db = admin.firestore();
    console.log("Firebase Admin initialized");
});

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");

// ─── TASK 2: Gemini AI Insights ───────────────────────────────────────────────

exports.onDailySummaryCreated = onDocumentCreated(
  {
    document: "users/{uid}/children/{childId}/logs/{logId}",
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    if (data.type !== "dailySummary") return;

    const { uid, childId } = event.params;
    const logsRef = db.collection(`users/${uid}/children/${childId}/logs`);
    const summariesSnap = await logsRef
      .where("type", "==", "dailySummary")
      .orderBy("date", "desc")
      .limit(7)
      .get();

    const daysLogged = summariesSnap.size;
    const aiInsightsRef = db.doc(`users/${uid}/children/${childId}/aiInsights`);

    if (daysLogged < 7) {
      await aiInsightsRef.set({ isUnlocked: false, daysLogged }, { merge: true });
      return;
    }

    const childSnap = await db.doc(`users/${uid}/children/${childId}`).get();
    const childData = childSnap.data() || {};
    const childAge = childData.age || "unknown";
    const asdLevel = childData.asdLevel || "unknown";

    const summaries = summariesSnap.docs.map((d) => d.data());
    const summariesJSON = JSON.stringify(summaries, null, 2);

    try {
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

      const prompt = `You are a clinical behavioral analyst assistant for parents of children with autism.
Based on the last 7 daily summaries for a child aged ${childAge}, ASD Level ${asdLevel}:
${summariesJSON}
Respond ONLY with this JSON (no markdown, no extra text):
{
  "summary": "2-3 sentence plain-language summary of this week's patterns",
  "progressDirection": "improving|stable|needs_attention",
  "tips": ["tip1", "tip2", "tip3"],
  "positiveMomentsHighlight": "1 sentence highlighting a positive trend"
}`;

      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();
      const insights = JSON.parse(text);

      await aiInsightsRef.set(
        {
          isUnlocked: true,
          daysLogged,
          generatedAt: admin.firestore.FieldValue.serverTimestamp(),
          weeklyInsights: {
            summary: insights.summary,
            progressDirection: insights.progressDirection,
            tips: insights.tips,
            positiveMomentsHighlight: insights.positiveMomentsHighlight,
          },
        },
        { merge: true }
      );
    } catch (error) {
      console.error("Gemini call failed:", error);
      await aiInsightsRef.set(
        { isUnlocked: false, error: "generation_failed" },
        { merge: true }
      );
    }
  }
);

// ─── TASK 3: Patient Link Backend ─────────────────────────────────────────────

exports.sendLinkRequest = onCall(
  { secrets: [GMAIL_APP_PASSWORD] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const { therapistEmail, childId } = request.data;
    if (!therapistEmail || !childId) {
      throw new HttpsError("invalid-argument", "therapistEmail and childId are required.");
    }

    const parentId = request.auth.uid;

    const therapistsSnap = await db
      .collection("therapists")
      .where("email", "==", therapistEmail)
      .limit(1)
      .get();

    if (therapistsSnap.empty) {
      throw new HttpsError("not-found", "No therapist found with that email address.");
    }

    const therapistDoc = therapistsSnap.docs[0];
    const therapistId = therapistDoc.id;
    const therapistData = therapistDoc.data();

    const childSnap = await db.doc(`users/${parentId}/children/${childId}`).get();
    if (!childSnap.exists) {
      throw new HttpsError("not-found", "Child not found.");
    }
    const childData = childSnap.data();

    const parentSnap = await db.doc(`users/${parentId}`).get();
    const parentData = parentSnap.data() || {};

    const existingRequest = await db
      .collection(`therapists/${therapistId}/pendingRequests`)
      .where("childId", "==", childId)
      .limit(1)
      .get();

    if (!existingRequest.empty) {
      throw new HttpsError("already-exists", "A request for this child is already pending.");
    }

    const existingLink = await db
      .doc(`therapists/${therapistId}/patients/${childId}`)
      .get();

    if (existingLink.exists) {
      throw new HttpsError("already-exists", "This therapist is already linked to your child.");
    }

    const requestRef = await db
      .collection(`therapists/${therapistId}/pendingRequests`)
      .add({
        parentId,
        childId,
        childName: childData.name || "your child",
        parentName: parentData.name || "A parent",
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "pending",
      });

    const nodemailer = require("nodemailer");
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "autilog.app@gmail.com",
        pass: GMAIL_APP_PASSWORD.value(),
      },
    });

    await transporter.sendMail({
      from: '"AutiLog" <autilog.app@gmail.com>',
      to: therapistEmail,
      subject: "New patient link request on AutiLog",
      html: `
        <div style="font-family:sans-serif;max-width:480px;margin:auto;">
          <h2 style="color:#4A90D9;">AutiLog — New Link Request</h2>
          <p>Hello ${therapistData.name || ""},</p>
          <p><strong>${parentData.name || "A parent"}</strong> has sent you a link request
          for their child <strong>${childData.name || ""}</strong>.</p>
          <p>Open the <strong>AutiLog app</strong> to accept or reject this request.</p>
          <br/>
          <p style="color:#888;font-size:12px;">AutiLog — Supporting autism care together.</p>
        </div>
      `,
    });

    return { success: true, requestId: requestRef.id };
  }
);

exports.acceptLinkRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const { requestId } = request.data;
  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId is required.");
  }

  const therapistId = request.auth.uid;

  const requestRef = db.doc(`therapists/${therapistId}/pendingRequests/${requestId}`);
  const requestSnap = await requestRef.get();

  if (!requestSnap.exists) {
    throw new HttpsError("not-found", "Request not found.");
  }

  const requestData = requestSnap.data();
  const { parentId, childId, childName } = requestData;

  const therapistSnap = await db.doc(`therapists/${therapistId}`).get();
  const therapistData = therapistSnap.data() || {};

  const batch = db.batch();

  batch.set(db.doc(`therapists/${therapistId}/patients/${childId}`), {
    parentId,
    childName: childName || "",
    linkedAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "active",
  });

  batch.set(
    db.doc(`users/${parentId}/children/${childId}/linkedTherapists/${therapistId}`),
    {
      therapistName: therapistData.name || "Your therapist",
      linkedAt: admin.firestore.FieldValue.serverTimestamp(),
    }
  );

  batch.delete(requestRef);
  await batch.commit();

  return { success: true };
});

exports.rejectLinkRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const { requestId } = request.data;
  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId is required.");
  }

  const therapistId = request.auth.uid;

  const requestRef = db.doc(`therapists/${therapistId}/pendingRequests/${requestId}`);
  const requestSnap = await requestRef.get();

  if (!requestSnap.exists) {
    throw new HttpsError("not-found", "Request not found.");
  }

  await requestRef.delete();

  return { success: true };
});