import 'package:formz/formz.dart';

enum RequiredTextValidationError { empty }

/// Generic validator for any required non-empty text field
/// (e.g. name, licence number, clinic name, specialisation).
class RequiredTextInput extends FormzInput<String, RequiredTextValidationError> {
  const RequiredTextInput.pure() : super.pure('');
  const RequiredTextInput.dirty([super.value = '']) : super.dirty();

  @override
  RequiredTextValidationError? validator(String value) {
    return value.trim().isEmpty ? RequiredTextValidationError.empty : null;
  }
}

extension RequiredTextValidationErrorX on RequiredTextValidationError {
  String fieldMessage(String fieldName) => '$fieldName is required.';
}
