/**
 * Dev utility — seeds a single test session into Firestore so the Session
 * Detail / Join flow can be exercised before the scheduling UI exists.
 *
 * Auth: uses Application Default Credentials. Point GOOGLE_APPLICATION_CREDENTIALS
 * at a service-account key first (see the run instructions printed on error).
 *
 * Usage (from the functions/ directory):
 *   node scripts/seed_session.js <therapistUid> [offsetMinutes] [childName]
 *
 *   <therapistUid>   required — the signed-in therapist's Auth UID.
 *   [offsetMinutes]  optional — start time relative to now. Default -5
 *                    (started 5 min ago => inside the join window).
 *                    Use a big positive number (e.g. 1440) to test the
 *                    disabled "opens 15 min before" state.
 *   [childName]      optional — display name. Default "Test Child".
 *
 * Prints the new session id and the JaaS room it maps to.
 */
const admin = require("firebase-admin");

async function main() {
  const therapistId = process.argv[2];
  const offsetMinutes = Number(process.argv[3] ?? -5);
  const childName = process.argv[4] ?? "Test Child";

  if (!therapistId) {
    console.error("ERROR: missing <therapistUid>.\n");
    console.error("Usage: node scripts/seed_session.js <therapistUid> [offsetMinutes] [childName]");
    process.exit(1);
  }

  admin.initializeApp();
  const db = admin.firestore();

  const start = new Date(Date.now() + offsetMinutes * 60 * 1000);
  const end = new Date(start.getTime() + 45 * 60 * 1000);

  const session = {
    therapistId,
    childId: "test-child",
    childName,
    parentId: "test-parent",
    scheduledAt: admin.firestore.Timestamp.fromDate(start),
    endTime: admin.firestore.Timestamp.fromDate(end),
    location: "Online",
    mode: "Virtual",
    status: "upcoming",
  };

  const ref = await db.collection("sessions").add(session);

  console.log("✓ Seeded session:");
  console.log("  id:        ", ref.id);
  console.log("  room:      ", `autilog-${ref.id}`);
  console.log("  therapist: ", therapistId);
  console.log("  start:     ", start.toISOString(), `(now ${offsetMinutes >= 0 ? "+" : ""}${offsetMinutes} min)`);
  console.log("  end:       ", end.toISOString());
  console.log("\nOpen the therapist home → the session card appears under today → tap → Join.");
}

main().catch((err) => {
  console.error("Seed failed:", err.message);
  console.error(
    "\nMost likely missing credentials. Download a service-account key from\n" +
      "Firebase Console → Project settings → Service accounts → Generate new private key,\n" +
      "then run (PowerShell):\n" +
      '  $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\to\\serviceAccountKey.json"\n' +
      "  node scripts/seed_session.js <therapistUid>"
  );
  process.exit(1);
});
