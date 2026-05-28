import '../../../shared/models/positive_moment_model.dart';

/// Route arguments for positive-moment screens (kept separate from UI files).
class PositiveMomentFormArgs {
  final String patientId;
  final String patientName;
  final PositiveMomentModel? existingMoment;

  const PositiveMomentFormArgs({
    required this.patientId,
    required this.patientName,
    this.existingMoment,
  });
}

PositiveMomentFormArgs? positiveMomentFormArgsFromUri(Uri uri) {
  final extra = uri.queryParameters;
  final patientId = extra['patientId'];
  final patientName = extra['patientName'];
  if (patientId == null ||
      patientId.isEmpty ||
      patientName == null ||
      patientName.isEmpty) {
    return null;
  }
  return PositiveMomentFormArgs(
    patientId: patientId,
    patientName: patientName,
  );
}