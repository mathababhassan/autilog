part of 'parent_registration_bloc.dart';

class ParentRegistrationState extends Equatable {
  const ParentRegistrationState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.gender,
    this.profilePhotoPath,
    this.childName = '',
    this.childAge = '',
    this.asdSeverity = '',
    this.termsAccepted = false,
    this.status = FormzSubmissionStatus.initial,
    this.serverError,
    // Field-level validation errors (null = no error)
    this.nameError,
    this.emailError,
    this.passwordError,
    this.childNameError,
    this.childAgeError,
    this.asdSeverityError,
    this.termsError,
  });

  final String name;
  final String email;
  final String password;
  final String? gender;
  final String? profilePhotoPath;
  final String childName;
  final String childAge;
  final String asdSeverity;
  final bool termsAccepted;

  final FormzSubmissionStatus status;
  final String? serverError;

  // Validation errors
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? childNameError;
  final String? childAgeError;
  final String? asdSeverityError;
  final String? termsError;

  // ── Password strength helpers ────────────────────────────────────────────

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
    String? childName,
    String? childAge,
    String? asdSeverity,
    bool? termsAccepted,
    FormzSubmissionStatus? status,
    String? serverError,
    String? nameError,
    String? emailError,
    String? passwordError,
    String? childNameError,
    String? childAgeError,
    String? asdSeverityError,
    String? termsError,
    // Allow explicitly clearing optional fields
    bool clearServerError = false,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearChildNameError = false,
    bool clearChildAgeError = false,
    bool clearAsdSeverityError = false,
    bool clearTermsError = false,
    bool clearProfilePhoto = false,
    bool clearGender = false,
  }) {
    return ParentRegistrationState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: clearGender ? null : (gender ?? this.gender),
      profilePhotoPath: clearProfilePhoto
          ? null
          : (profilePhotoPath ?? this.profilePhotoPath),
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
      asdSeverity: asdSeverity ?? this.asdSeverity,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      status: status ?? this.status,
      serverError: clearServerError ? null : (serverError ?? this.serverError),
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      childNameError:
          clearChildNameError ? null : (childNameError ?? this.childNameError),
      childAgeError:
          clearChildAgeError ? null : (childAgeError ?? this.childAgeError),
      asdSeverityError: clearAsdSeverityError
          ? null
          : (asdSeverityError ?? this.asdSeverityError),
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
        childName,
        childAge,
        asdSeverity,
        termsAccepted,
        status,
        serverError,
        nameError,
        emailError,
        passwordError,
        childNameError,
        childAgeError,
        asdSeverityError,
        termsError,
      ];
}