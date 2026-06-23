import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';

/// Registers this device's FCM token on the signed-in user's profile doc so the
/// notification backend can target pushes. Tokens are stored as an `fcmTokens`
/// array on `parents/{uid}` or `therapists/{uid}` (the same docs the
/// createNotification push step reads). Best-effort: never blocks the app.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Web Push (VAPID) key — required for getToken() on web, ignored on Android.
  // Firebase console → Project settings → Cloud Messaging → Web configuration →
  // Web Push certificates → "Key pair". Paste that value here to test on Chrome.
  static const String _webVapidKey = 'BLbcY-v7_3fJEPVCrXBBzTiba9SMdUFW8HwloRCX2FiiD5Vu9fFomRm_Z4ISevFJbG-9XQdxMF0KcyjBoOSKjpA';

  String? _uid;
  String? _role;
  bool _refreshListenerAttached = false;

  Future<String?> _getToken() => kIsWeb
      ? _messaging.getToken(vapidKey: _webVapidKey)
      : _messaging.getToken();

  /// Call once the user is authenticated (with their role). Asks notification
  /// permission, stores the current token, and keeps it fresh on rotation.
  Future<void> register({required String uid, required String role}) async {
    _uid = uid;
    _role = role;
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _getToken();
      if (token != null) await _saveToken(token);

      if (!_refreshListenerAttached) {
        _refreshListenerAttached = true;
        // Always saves against the CURRENT user (fields updated on each login).
        _messaging.onTokenRefresh.listen(_saveToken);
      }
    } catch (e) {
      // Push is best-effort; a registration failure must not break the app.
      debugPrint('[push] register failed: $e');
    }
  }

  /// Removes this device's token from the user's profile so they stop receiving
  /// pushes after logout. Call BEFORE signing out (writes need the auth still
  /// active). Best-effort.
  Future<void> unregister() async {
    try {
      final uid = _uid;
      if (uid != null) {
        final token = await _getToken();
        if (token != null) {
          final collection = _role == 'therapist' ? 'therapists' : 'parents';
          await FirebaseFirestore.instance.collection(collection).doc(uid).set(
            {'fcmTokens': FieldValue.arrayRemove(<String>[token])},
            SetOptions(merge: true),
          );
        }
      }
    } catch (_) {
      // Best-effort; never block logout.
    }
    _uid = null;
    _role = null;
  }

  Future<void> _saveToken(String token) async {
    final uid = _uid;
    if (uid == null) return;
    final collection = _role == 'therapist' ? 'therapists' : 'parents';
    await FirebaseFirestore.instance.collection(collection).doc(uid).set(
      {'fcmTokens': FieldValue.arrayUnion(<String>[token])},
      SetOptions(merge: true),
    );
  }

  // ── Message handling (A9c) ─────────────────────────────────────────────────

  /// Set on MaterialApp.router so foreground pushes can show an in-app SnackBar.
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void Function(Map<String, dynamic> data)? _onOpen;

  /// Wires foreground display + tap navigation. Call once after the router
  /// exists. `onOpen` receives the message `data` (contains `target` JSON).
  void attachHandlers({
    required void Function(Map<String, dynamic> data) onOpen,
  }) {
    _onOpen = onOpen;
    // Foreground: FCM does not auto-display, so we show it ourselves.
    FirebaseMessaging.onMessage.listen(_showForeground);
    // Tap that opened the app from the background.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _onOpen?.call(m.data));
    // Tap that launched the app from a terminated state.
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _onOpen?.call(m.data);
    });
  }

  void _showForeground(RemoteMessage message) {
    final title = message.notification?.title ??
        (message.data['type'] as String?) ??
        'New notification';
    final body = message.notification?.body ?? '';
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title — $body'),
        duration: const Duration(seconds: 5),
        action: _onOpen == null
            ? null
            : SnackBarAction(
                label: 'View',
                onPressed: () => _onOpen!(message.data),
              ),
      ),
    );
  }
}
