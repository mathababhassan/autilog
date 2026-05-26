abstract final class Routes {
  static const String splash = '/splash';  
  static const String roleSelection = '/auth/register';

  static const String login = '/auth/login';

  // Therapist
  static const String registerTherapist = '/auth/register/therapist';
  static const String therapistHome = '/therapist/home';
  static const String therapistProfile = '/therapist/profile';
  static const String therapistProfileEdit = '/therapist/profile/edit';
  static const String therapistPatients = '/therapist/patients';

  // Parent
  static const String registerParent = '/auth/register/parent';
  static const String parentHome = '/parent/home';
  static const String parentProfile = '/parent/profile';
  static const String incidentForm = '/parent/log/incident';
  static const String incidentDetail = '/parent/log/incident-detail';

  // Child
  static const String childOnboarding = '/child-onboarding';
  static const String childRegistration = '/child-step2';

  static const String childProfile = '/parent/child-profile';

  // shared
  static const String forgotPassword = '/auth/forgot-password';
}