import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-side access to the notification records written by the backend
/// (`functions/notifications.js`):
///   parents/{uid}/notifications/{id}
///   therapists/{uid}/notifications/{id}
/// Each record carries a `read` boolean (starts false).
///
/// Scoped for now to the unread-count badge. List / markRead / delete /
/// markAllRead are added here when the inbox screens (P-39 / T-35) are built.
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Live count of unread notifications for [uid], capped at 99 (the badge
  /// renders "9+" past 9). Emits 0 when signed-out; errors are swallowed so a
  /// transient permission/network blip never breaks the header.
  Stream<int> unreadCountStream({
    required String uid,
    required bool isTherapist,
  }) {
    if (uid.isEmpty) return Stream<int>.value(0);
    final collection = isTherapist ? 'therapists' : 'parents';
    return _db
        .collection(collection)
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .limit(99)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((_) {});
  }
}
