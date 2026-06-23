import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_model.dart';

/// Client-side access to the notification records written by the backend
/// (`functions/notifications.js`):
///   parents/{uid}/notifications/{id}
///   therapists/{uid}/notifications/{id}
/// Each record carries a `read` boolean (starts false).
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ─── helpers ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _col({
    required String uid,
    required bool isTherapist,
  }) {
    final root = isTherapist ? 'therapists' : 'parents';
    return _db.collection(root).doc(uid).collection('notifications');
  }

  // ─── unread count badge ──────────────────────────────────────────────────────

  /// Live count of unread notifications for [uid], capped at 99 (the badge
  /// renders "9+" past 9). Emits 0 when signed-out; errors are swallowed so a
  /// transient permission/network blip never breaks the header.
  Stream<int> unreadCountStream({
    required String uid,
    required bool isTherapist,
  }) {
    if (uid.isEmpty) return Stream<int>.value(0);
    return _col(uid: uid, isTherapist: isTherapist)
        .where('read', isEqualTo: false)
        .limit(99)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((_) {});
  }

  // ─── inbox list stream ───────────────────────────────────────────────────────

  /// Real-time stream of all notifications, newest first.
  Stream<List<NotificationModel>> notificationsStream({
    required String uid,
    required bool isTherapist,
  }) {
    if (uid.isEmpty) return Stream.value([]);
    return _col(uid: uid, isTherapist: isTherapist)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(NotificationModel.fromDoc).toList())
        .handleError((_) => <NotificationModel>[]);
  }

  // ─── mutations ───────────────────────────────────────────────────────────────

  /// Mark a single notification as read.
  Future<void> markAsRead({
    required String uid,
    required bool isTherapist,
    required String notificationId,
  }) async {
    await _col(uid: uid, isTherapist: isTherapist)
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark every notification for [uid] as read in a single batch write.
  Future<void> markAllAsRead({
    required String uid,
    required bool isTherapist,
  }) async {
    final snap = await _col(uid: uid, isTherapist: isTherapist)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
