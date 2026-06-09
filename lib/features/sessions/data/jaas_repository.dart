import 'package:cloud_functions/cloud_functions.dart';

/// Result of minting a JaaS (8x8) join token server-side.
///
/// The Cloud Function returns the signed JWT plus the room name and AppID so
/// the client can assemble the join URL without hard-coding the AppID.
class JaasTokenResult {
  const JaasTokenResult({
    required this.token,
    required this.room,
    required this.appId,
  });

  final String token;
  final String room;
  final String appId;

  /// The full 8x8.vc URL the therapist opens to enter the call.
  /// e.g. `https://8x8.vc/{appId}/autilog-{sessionId}?jwt={token}`
  Uri get joinUrl =>
      Uri.parse('https://8x8.vc/$appId/$room').replace(queryParameters: {
        'jwt': token,
      });
}

/// Talks to the `getJaasToken` Cloud Function. Unlike [SessionRepository]
/// (Firestore), this calls a callable function, so it lives in its own class.
class JaasRepository {
  JaasRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Asks the server for a short-lived join token for [sessionId].
  /// Throws on auth/permission/network failure (the BLoC maps to a friendly
  /// message).
  Future<JaasTokenResult> fetchJoinToken(String sessionId) async {
    final callable = _functions.httpsCallable('getJaasToken');
    final result = await callable.call<Object?>({'sessionId': sessionId});

    // The callable plugin can hand back Map<Object?, Object?> on some
    // platforms, so normalise before reading.
    final data = Map<String, dynamic>.from(result.data as Map);
    return JaasTokenResult(
      token: data['token'] as String,
      room: data['room'] as String,
      appId: data['appId'] as String,
    );
  }
}
