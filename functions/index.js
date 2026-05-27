const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { onInit } = require("firebase-functions/v2/core");

let db;

// Define secrets at the top level (outside any function)
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");

onInit(async () => {
    if (!admin.apps.length) {
        admin.initializeApp();
    }
    db = admin.firestore();
    console.log("Firebase Admin initialized");
});

// ─── Gemini AI Insights ───────────────────────────────────────────────

exports.onDailySummaryCreated = onDocumentCreated(
  {
    document: "parents/{parentId}/children/{childId}/dailySummaries/{summaryId}",
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    // Import Gemini INSIDE the function (lazy load)
    const { GoogleGenerativeAI } = require("@google/generative-ai");
    
    const snap = event.data;
    if (!snap) return;

    const { parentId, childId } = event.params;
    
    // Get daily summaries
    const summariesRef = db.collection(`parents/${parentId}/children/${childId}/dailySummaries`);
    const summariesSnap = await summariesRef
      .orderBy("date", "desc")
      .limit(7)
      .get();

    const daysLogged = summariesSnap.size;
    const aiInsightsRef = db.doc(`parents/${parentId}/children/${childId}/aiInsights`);

    if (daysLogged < 7) {
      await aiInsightsRef.set({ isUnlocked: false, daysLogged }, { merge: true });
      return;
    }

    // Get child info
    const childSnap = await db.doc(`parents/${parentId}/children/${childId}`).get();
    const childData = childSnap.data() || {};
    const childName = childData.name || "your child";
    const childAge = childData.age || "unknown";

    const summaries = summariesSnap.docs.map((d) => d.data());
    const summariesJSON = JSON.stringify(summaries, null, 2);

    // Get positive moments
    let positiveMomentsJSON = "[]";
    try {
      const momentsSnap = await db
        .collection(`parents/${parentId}/children/${childId}/positiveMoments`)
        .orderBy("date", "desc")
        .limit(7)
        .get();
      if (!momentsSnap.empty) {
        positiveMomentsJSON = JSON.stringify(
          momentsSnap.docs.map((d) => d.data()),
          null,
          2
        );
      }
    } catch (err) {
      console.warn("Could not load positive moments:", err.message);
    }

    // Get incidents
    let incidentsJSON = "[]";
    try {
      const incidentsSnap = await db
        .collection(`parents/${parentId}/children/${childId}/incidents`)
        .orderBy("date", "desc")
        .limit(7)
        .get();
      if (!incidentsSnap.empty) {
        incidentsJSON = JSON.stringify(
          incidentsSnap.docs.map((d) => d.data()),
          null,
          2
        );
      }
    } catch (err) {
      console.warn("Could not load incidents:", err.message);
    }

    try {
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

      const prompt = `You are a clinical behavioral analyst assistant for parents of children with autism.
Child: ${childName}, Age: ${childAge}

Based on the last 7 daily summaries (sleep, mood, meals, routine):
${summariesJSON}

Recent positive moments logged:
${positiveMomentsJSON}

Recent behavioral incidents (meltdowns, triggers, severity):
${incidentsJSON}

Respond ONLY with this JSON (no markdown, no extra text):
{
  "summary": "2-3 sentence plain-language summary of this week's patterns",
  "progressDirection": "improving|stable|needs_attention",
  "tips": ["tip1", "tip2", "tip3"],
  "positiveMomentsHighlight": "1 sentence highlighting a positive trend",
  "incidentPattern": "1 sentence about incident patterns if any"
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
            incidentPattern: insights.incidentPattern,
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

// ─── Patient Link Backend ─────────────────────────────────────────────

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

    const childSnap = await db.doc(`parents/${parentId}/children/${childId}`).get();
    if (!childSnap.exists) {
      throw new HttpsError("not-found", "Child not found.");
    }
    const childData = childSnap.data();

    const parentSnap = await db.doc(`parents/${parentId}`).get();
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
    db.doc(`parents/${parentId}/children/${childId}/linkedTherapists/${therapistId}`),
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

// ─── Positive Moment Backend ─────────────────────────────────────────

const {
  onPositiveMomentCreated,
  onPositiveMomentUpdated,
  onPositiveMomentDeleted,
} = require("./positive_moment");

exports.onPositiveMomentCreated = onPositiveMomentCreated;
exports.onPositiveMomentUpdated = onPositiveMomentUpdated;
exports.onPositiveMomentDeleted = onPositiveMomentDeleted;