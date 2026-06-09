const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");
// JaaS (8x8) RS256 private key for signing meeting JWTs. Set via:
//   firebase functions:secrets:set JAAS_PRIVATE_KEY
const JAAS_PRIVATE_KEY = defineSecret("JAAS_PRIVATE_KEY");

// JaaS app identifiers — NOT secret (they appear in the join URL / JWT header).
const JAAS_APP_ID = "vpaas-magic-cookie-ee35ab3fd28f4bceaa1f898c313e6c8a";
const JAAS_KID =
  "vpaas-magic-cookie-ee35ab3fd28f4bceaa1f898c313e6c8a/7bc83c";

// ─── Gemini AI Insights ───────────────────────────────────────────────

exports.onDailySummaryCreated = onDocumentCreated(
  {
    document: "parents/{parentId}/children/{childId}/dailySummaries/{summaryId}",
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    const { GoogleGenerativeAI } = require("@google/generative-ai");

    const snap = event.data;
    if (!snap) return;

    const { parentId, childId } = event.params;

    const summariesRef = db.collection(`parents/${parentId}/children/${childId}/dailySummaries`);
    const summariesSnap = await summariesRef
      .orderBy("date", "desc")
      .limit(7)
      .get();

    const daysLogged = summariesSnap.size;
    const aiInsightsRef = db.doc(`parents/${parentId}/children/${childId}/aiInsights/current`);

    if (daysLogged < 7) {
      await aiInsightsRef.set({ isUnlocked: false, daysLogged }, { merge: true });
      return;
    }

    const childSnap = await db.doc(`parents/${parentId}/children/${childId}`).get();
    const childData = childSnap.data() || {};
    const childName = childData.name || "your child";
    const childAge = childData.age || "unknown";

    const summaries = summariesSnap.docs.map((d) => d.data());
    const summariesJSON = JSON.stringify(summaries, null, 2);

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
      const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

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
      // Don't overwrite isUnlocked if already true
      const existing = await aiInsightsRef.get();
      if (!existing.exists || existing.data()?.isUnlocked !== true) {
        await aiInsightsRef.set(
          { isUnlocked: false, error: "generation_failed" },
          { merge: true }
        );
      }
    }
  }
);

// ─── Patient Link Backend ─────────────────────────────────────────────

exports.sendLinkRequest = onCall(
  { secrets: [GMAIL_APP_PASSWORD] },
  async (request) => {
    const nodemailer = require("nodemailer");

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

// ─── Virtual Session — JaaS Join Token ────────────────────────────────

exports.getJaasToken = onCall(
  { secrets: [JAAS_PRIVATE_KEY] },
  async (request) => {
    const jwt = require("jsonwebtoken");

    // 1. Must be signed in.
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to join a call.");
    }

    // 2. sessionId is required and must point at a real session.
    const { sessionId } = request.data || {};
    if (!sessionId || typeof sessionId !== "string") {
      throw new HttpsError("invalid-argument", "A sessionId is required.");
    }

    const sessionSnap = await db.doc(`sessions/${sessionId}`).get();
    if (!sessionSnap.exists) {
      throw new HttpsError("not-found", "Session not found.");
    }
    const session = sessionSnap.data();

    // 3. Only the session's therapist may mint a moderator token.
    const uid = request.auth.uid;
    if (session.therapistId !== uid) {
      throw new HttpsError(
        "permission-denied",
        "You are not the therapist for this session."
      );
    }

    // 4. Mint a short-lived RS256 JaaS JWT. Identity comes from the verified
    //    Firebase Auth token, never from client-supplied data.
    const authToken = request.auth.token || {};
    const room = `autilog-${sessionId}`;

    const payload = {
      aud: "jitsi",
      iss: "chat",
      sub: JAAS_APP_ID,
      room,
      context: {
        user: {
          id: uid,
          name: authToken.name || "Therapist",
          email: authToken.email || "",
          avatar: authToken.picture || "",
          moderator: true,
        },
      },
    };

    const token = jwt.sign(payload, JAAS_PRIVATE_KEY.value(), {
      algorithm: "RS256",
      keyid: JAAS_KID, // sets the `kid` JWT header
      expiresIn: "2h", // sets `exp`
      notBefore: "-10s", // small clock-skew tolerance for `nbf`
    });

    // 5. Client builds the join URL from these.
    return { token, room, appId: JAAS_APP_ID };
  }
);

const { onDocumentDeleted } = require("firebase-functions/v2/firestore");

exports.onDailySummaryDeleted = require("firebase-functions/v2/firestore").onDocumentDeleted(
  {
    document: "parents/{parentId}/children/{childId}/dailySummaries/{summaryId}",
  },
  async (event) => {
    const { parentId, childId } = event.params;

    const summariesSnap = await db
      .collection(`parents/${parentId}/children/${childId}/dailySummaries`)
      .get();

    const daysLogged = summariesSnap.size;
    const aiInsightsRef = db.doc(`parents/${parentId}/children/${childId}/aiInsights/current`);

    await aiInsightsRef.set(
      { daysLogged, isUnlocked: daysLogged >= 7 },
      { merge: true }
    );
  }
);

// ─── Positive Moment Backend ─────────────────────────────────────────

const {
  onPositiveMomentCreated,
  onPositiveMomentUpdated,
  onPositiveMomentDeleted,
} = require("./positive_moment");

exports.onPositiveMomentCreated = onPositiveMomentCreated;
exports.onPositiveMomentUpdated = onPositiveMomentUpdated;
exports.onPositiveMomentDeleted = onPositiveMomentDeleted;