part of 'parent_registration_bloc.dart';

class ParentRegistrationState extends Equatable {
  const ParentRegistrationState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.gender,
    this.profilePhotoPath,
    this.termsAccepted = false,
    this.status = FormzSubmissionStatus.initial,
    this.serverError,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.termsError,
  });

  final String name;
  final String email;
  final String password;
  final String? gender;
  final String? profilePhotoPath;
  final bool termsAccepted;

  final FormzSubmissionStatus status;
  final String? serverError;

  // Validation errors
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? termsError;

  // ── Password strength helpers ─────────────────────────────────────────────

  bool get hasMinLength => password.length >= 8;
  bool get hasNumber => password.contains(RegExp(r'\d'));
  bool get hasSpecialChar =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  /// 0 = empty, 1 = weak, 2 = medium, 3 = strong
  int get passwordStrength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (hasMinLength) score++;
    if (hasNumber) score++;
    if (hasSpecialChar) score++;
    return score;
  }

  String get passwordStrengthLabel {
    switch (passwordStrength) {
      case 1:
        return 'Weak password';
      case 2:
        return 'Medium password';
      case 3:
        return 'Strong password';
      default:
        return '';
    }
  }

  ParentRegistrationState copyWith({
    String? name,
    String? email,
    String? password,
    String? gender,
    String? profilePhotoPath,
    bool? termsAccepted,
    FormzSubmissionStatus? status,
    String? serverError,
    String? nameError,
    String? emailError,
    String? passwordError,
    String? termsError,
    // Explicit clear flags so nullable fields can be set back to null
    bool clearServerError = false,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearTermsError = false,
    bool clearProfilePhoto = false,
    bool clearGender = false,
  }) {
    return ParentRegistrationState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: clearGender ? null : (gender ?? this.gender),
      profilePhotoPath:
          clearProfilePhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
      termsAccepted: termsAccepted ?? this.termsAccepted,
      status: status ?? this.status,
      serverError: clearServerError ? null : (serverError ?? this.serverError),
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      termsError: clearTermsError ? null : (termsError ?? this.termsError),
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        gender,
        profilePhotoPath,
        termsAccepted,
        status,
        serverError,
        nameError,
        emailError,
        passwordError,
        termsError,
      ];
}