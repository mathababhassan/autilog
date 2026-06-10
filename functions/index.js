const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const GROQ_API_KEY = defineSecret("GROQ_API_KEY");
const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");
const JAAS_PRIVATE_KEY = defineSecret("JAAS_PRIVATE_KEY");

const JAAS_APP_ID = "vpaas-magic-cookie-ee35ab3fd28f4bceaa1f898c313e6c8a";
const JAAS_KID = "vpaas-magic-cookie-ee35ab3fd28f4bceaa1f898c313e6c8a/7bc83c";

// ─── Shared AI data fetcher ───────────────────────────────────────────

async function fetchChildAIData(parentId, childId) {
  const childSnap = await db.doc(`parents/${parentId}/children/${childId}`).get();
  const childData = childSnap.data() || {};
  const childName = childData.name || "the child";
  const childAge = childData.age || "unknown";

  let summariesJSON = "[]";
  try {
    const snap = await db
      .collection(`parents/${parentId}/children/${childId}/dailySummaries`)
      .orderBy("date", "desc")
      .limit(7)
      .get();
    if (!snap.empty) summariesJSON = JSON.stringify(snap.docs.map((d) => d.data()), null, 2);
  } catch (err) {
    console.warn("Could not load daily summaries:", err.message);
  }

  let incidentsJSON = "[]";
  try {
    const snap = await db
      .collection(`parents/${parentId}/children/${childId}/incidents`)
      .orderBy("date", "desc")
      .limit(7)
      .get();
    if (!snap.empty) incidentsJSON = JSON.stringify(snap.docs.map((d) => d.data()), null, 2);
  } catch (err) {
    console.warn("Could not load incidents:", err.message);
  }

  let positiveMomentsJSON = "[]";
  try {
    const snap = await db
      .collection(`parents/${parentId}/children/${childId}/positiveMoments`)
      .orderBy("date", "desc")
      .limit(7)
      .get();
    if (!snap.empty) positiveMomentsJSON = JSON.stringify(snap.docs.map((d) => d.data()), null, 2);
  } catch (err) {
    console.warn("Could not load positive moments:", err.message);
  }

  return { childName, childAge, summariesJSON, incidentsJSON, positiveMomentsJSON };
}

async function callGroq(apiKey, prompt) {
  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.4,
    }),
  });
  const data = await response.json();
  const text = data.choices[0].message.content.trim();
  return JSON.parse(text);
}

// ─── Trigger 1: Daily Summary Created ────────────────────────────────
// Updates: summary, sleepTip, strategyTip1, strategyTip2, progressDirection, daysLogged, isUnlocked

exports.onDailySummaryCreated = onDocumentCreated(
  {
    document: "parents/{parentId}/children/{childId}/dailySummaries/{summaryId}",
    secrets: [GROQ_API_KEY],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { parentId, childId } = event.params;

    const summariesRef = db.collection(`parents/${parentId}/children/${childId}/dailySummaries`);
    const countSnap = await summariesRef.get();
    const daysLogged = countSnap.size;

    const aiInsightsRef = db.doc(`parents/${parentId}/children/${childId}/aiInsights/current`);

    if (daysLogged < 7) {
      await aiInsightsRef.set({ isUnlocked: false, daysLogged }, { merge: true });
      return;
    }

    const { childName, childAge, summariesJSON, incidentsJSON, positiveMomentsJSON } =
      await fetchChildAIData(parentId, childId);

    const prompt = `You are a clinical behavioral analyst assistant for parents of children with autism.
Child: ${childName}, Age: ${childAge}

Last 7 daily summaries (sleep, mood, meals, routine):
${summariesJSON}

Recent behavioral incidents:
${incidentsJSON}

Recent positive moments:
${positiveMomentsJSON}

Respond ONLY with this JSON (no markdown, no extra text):
{
  "summary": "2-3 sentence plain-language summary of this week's patterns referencing specific details like sleep hours, mood scores, or routines",
  "progressDirection": "improving|stable|needs_attention",
  "sleepTip": "1 specific actionable tip about sleep based on the data",
  "strategyTip1": "1 specific behavioral strategy tip based on the data",
  "strategyTip2": "1 specific environmental or routine tip based on the data"
}`;

    try {
      const insights = await callGroq(GROQ_API_KEY.value(), prompt);

      await aiInsightsRef.set({
        isUnlocked: true,
        daysLogged,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        weeklyInsights: {
          summary: insights.summary,
          progressDirection: insights.progressDirection,
          sleepTip: insights.sleepTip,
          strategyTip1: insights.strategyTip1,
          strategyTip2: insights.strategyTip2,
        },
      }, { merge: true });

    } catch (error) {
      console.error("Groq call failed (daily summary trigger):", error);
      const existing = await aiInsightsRef.get();
      if (!existing.exists || existing.data()?.isUnlocked !== true) {
        await aiInsightsRef.set({ isUnlocked: false, error: "generation_failed" }, { merge: true });
      }
    }
  }
);

// ─── Trigger 2: Behavioral Incident Created ───────────────────────────
// Updates: incidentPattern, strategyTip1, strategyTip2, progressDirection

exports.onIncidentCreatedAI = onDocumentCreated(
  {
    document: "parents/{parentId}/children/{childId}/incidents/{incidentId}",
    secrets: [GROQ_API_KEY],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { parentId, childId } = event.params;

    const aiInsightsRef = db.doc(`parents/${parentId}/children/${childId}/aiInsights/current`);
    const existing = await aiInsightsRef.get();
    if (!existing.exists || existing.data()?.isUnlocked !== true) return;

    const { childName, childAge, summariesJSON, incidentsJSON, positiveMomentsJSON } =
      await fetchChildAIData(parentId, childId);

    const prompt = `You are a clinical behavioral analyst assistant for parents of children with autism.
Child: ${childName}, Age: ${childAge}

Last 7 daily summaries:
${summariesJSON}

Recent behavioral incidents (most recent just added):
${incidentsJSON}

Recent positive moments:
${positiveMomentsJSON}

Respond ONLY with this JSON (no markdown, no extra text):
{
  "progressDirection": "improving|stable|needs_attention",
  "incidentPattern": "1-2 sentences describing the pattern of triggers and behaviors observed across recent incidents, referencing specific triggers or settings",
  "strategyTip1": "1 specific behavioral de-escalation or prevention strategy based on the incident data",
  "strategyTip2": "1 specific environmental modification tip based on the incident triggers"
}`;

    try {
      const insights = await callGroq(GROQ_API_KEY.value(), prompt);

      await aiInsightsRef.set({
        weeklyInsights: {
          progressDirection: insights.progressDirection,
          incidentPattern: insights.incidentPattern,
          strategyTip1: insights.strategyTip1,
          strategyTip2: insights.strategyTip2,
        },
      }, { merge: true });

    } catch (error) {
      console.error("Groq call failed (incident trigger):", error);
    }
  }
);

// ─── Reports — AI Practice Summary (callable) ─────────────────────────

exports.getReportSummary = onCall(
  { secrets: [GROQ_API_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const { stats } = request.data || {};
    if (!stats) {
      throw new HttpsError("invalid-argument", "stats is required.");
    }

    const prompt = `You are a clinical assistant summarizing a therapist's caseload for the selected period.
Aggregated data across all their patients:
${JSON.stringify(stats, null, 2)}

Respond ONLY with this JSON (no markdown, no extra text):
{
  "summary": "2-3 sentence plain-language overview of trends across all patients this period, referencing the actual numbers",
  "focusArea": "1 sentence suggesting where the therapist should focus attention this period"
}`;

    try {
      const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${GROQ_API_KEY.value()}`,
        },
        body: JSON.stringify({
          model: "llama-3.3-70b-versatile",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.4,
        }),
      });

      const groqData = await response.json();
      const text = groqData.choices[0].message.content.trim();
      const insights = JSON.parse(text);

      return {
        summary: insights.summary,
        focusArea: insights.focusArea,
      };
    } catch (error) {
      console.error("Groq report summary failed:", error);
      throw new HttpsError("internal", "Failed to generate summary.");
    }
  }
);

// ─── Trigger 3: Positive Moment Created (AI only) ─────────────────────
// Updates: positiveMomentsHighlight, strategyTip1, strategyTip2, progressDirection

exports.onPositiveMomentCreatedAI = onDocumentCreated(
  {
    document: "parents/{parentId}/children/{childId}/positiveMoments/{momentId}",
    secrets: [GROQ_API_KEY],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { parentId, childId } = event.params;

    const aiInsightsRef = db.doc(`parents/${parentId}/children/${childId}/aiInsights/current`);
    const existing = await aiInsightsRef.get();
    if (!existing.exists || existing.data()?.isUnlocked !== true) return;

    const { childName, childAge, summariesJSON, incidentsJSON, positiveMomentsJSON } =
      await fetchChildAIData(parentId, childId);

    const prompt = `You are a clinical behavioral analyst assistant for parents of children with autism.
Child: ${childName}, Age: ${childAge}

Last 7 daily summaries:
${summariesJSON}

Recent behavioral incidents:
${incidentsJSON}

Recent positive moments (most recent just added):
${positiveMomentsJSON}

Respond ONLY with this JSON (no markdown, no extra text):
{
  "progressDirection": "improving|stable|needs_attention",
  "positiveMomentsHighlight": "1-2 sentences highlighting the positive trend or strength observed, referencing specific behaviors or settings",
  "strategyTip1": "1 specific tip to reinforce or build on the positive behaviors observed",
  "strategyTip2": "1 tip to create more opportunities for positive moments based on what worked"
}`;

    try {
      const insights = await callGroq(GROQ_API_KEY.value(), prompt);

      await aiInsightsRef.set({
        weeklyInsights: {
          progressDirection: insights.progressDirection,
          positiveMomentsHighlight: insights.positiveMomentsHighlight,
          strategyTip1: insights.strategyTip1,
          strategyTip2: insights.strategyTip2,
        },
      }, { merge: true });

    } catch (error) {
      console.error("Groq call failed (positive moment trigger):", error);
    }
  }
);

// ─── Daily Summary Deleted ────────────────────────────────────────────

exports.onDailySummaryDeleted = onDocumentDeleted(
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

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to join a call.");
    }

    const { sessionId } = request.data || {};
    if (!sessionId || typeof sessionId !== "string") {
      throw new HttpsError("invalid-argument", "A sessionId is required.");
    }

    const sessionSnap = await db.doc(`sessions/${sessionId}`).get();
    if (!sessionSnap.exists) {
      throw new HttpsError("not-found", "Session not found.");
    }
    const session = sessionSnap.data();

    if (session.mode !== 'virtual') {
      throw new HttpsError("failed-precondition", "Only virtual sessions can be joined via video call.");
    }

    if (session.status === 'cancelled') {
      throw new HttpsError("failed-precondition", "This session has been cancelled.");
    }

    const now = new Date();
    let sessionStart;
    if (session.startTime && typeof session.startTime.toDate === 'function') {
      sessionStart = session.startTime.toDate();
    } else if (session.startTime) {
      sessionStart = new Date(session.startTime);
    } else {
      throw new HttpsError("failed-precondition", "Session has no start time.");
    }

    const timeDiffMinutes = (now - sessionStart) / (1000 * 60);
    if (timeDiffMinutes < -15 || timeDiffMinutes > 15) {
      throw new HttpsError("failed-precondition", "Video call is only available 15 minutes before and after session start time.");
    }

    const uid = request.auth.uid;
    if (session.therapistId !== uid) {
      throw new HttpsError("permission-denied", "You are not the therapist for this session.");
    }

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
      keyid: JAAS_KID,
      expiresIn: "2h",
      notBefore: "-10s",
    });

    return { token, room, appId: JAAS_APP_ID };
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
