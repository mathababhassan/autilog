const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

exports.onDailySummaryCreated = onDocumentCreated(
  {
    document: "users/{uid}/children/{childId}/logs/{logId}",
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();

    // Exit early if this log is not a daily summary
    if (data.type !== "dailySummary") return;

    const { uid, childId } = event.params;
    const db = admin.firestore();

    // Fetch last 7 daily summaries for this child
    const logsRef = db.collection(`users/${uid}/children/${childId}/logs`);
    const summariesSnap = await logsRef
      .where("type", "==", "dailySummary")
      .orderBy("date", "desc")
      .limit(7)
      .get();

    const daysLogged = summariesSnap.size;
    const aiInsightsRef = db.doc(`children/${childId}/aiInsights`);

    // Not enough logs yet — update progress counter, no Gemini call
    if (daysLogged < 7) {
      await aiInsightsRef.set(
        { isUnlocked: false, daysLogged },
        { merge: true }
      );
      return;
    }

    // Fetch child profile for age and ASD level
    const childSnap = await db.doc(`users/${uid}/children/${childId}`).get();
    const childData = childSnap.data() || {};
    const childAge = childData.age || "unknown";
    const asdLevel = childData.asdLevel || "unknown";

    // Build summaries payload for Gemini
    const summaries = summariesSnap.docs.map((d) => d.data());
    const summariesJSON = JSON.stringify(summaries, null, 2);

    // Call Gemini
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