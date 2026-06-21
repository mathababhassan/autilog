import 'package:cloud_functions/cloud_functions.dart';

class QuickLogRepository {
  QuickLogRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> parseText({
    required String text,
    required String logType, // 'incident' | 'positiveMoment'
  }) async {
    final callable = _functions.httpsCallable('parseQuickLogText');
    final result = await callable.call<Object?>({
      'text': text,
      'logType': logType,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return Map<String, dynamic>.from(data['fields'] as Map);
  }
}
