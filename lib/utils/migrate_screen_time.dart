import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateScreenTime(String uid, String childId) async {
  final firestore = FirebaseFirestore.instance;

  final logsRef = firestore
      .collection('users')
      .doc(uid)
      .collection('children')
      .doc(childId)
      .collection('logs');

  final snapshot = await logsRef.get();

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final screenTimeHours = (data['screenTimeHours'] as num?)?.toDouble();

    final hadScreenTime = (screenTimeHours != null && screenTimeHours > 0);

    await doc.reference.set({
      'hadScreenTime': hadScreenTime,
    }, SetOptions(merge: true));
  }
}
