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
  static const String patientDetails = '/therapist/patients/details';
  static const String therapistSessions = '/therapist/sessions';
  static const String sessionDetail = '/therapist/session-detail';

  // Parent
  static const String registerParent = '/auth/register/parent';
  static const String parentHome = '/parent/home';
  static const String parentProfile = '/parent/profile';
  static const String incidentForm = '/parent/log/incident';
  static const String incidentDetail = '/parent/log/incident-detail';
  static const String logHistory = '/parent/log/history';
  static const String aiInsights = '/parent/ai-insights';
  static const String parentSessions = '/parent/sessions';

  static const String dailySummary = '/parent/log/daily-summary';

  static const String positiveMomentForm = '/parent/log/positive_moment';
  static const String positiveMomentDetail = '/parent/log/positive_moment_detail';
  static const String dailySummaryDetail = '/parent/log/daily-summary-detail';
  

  /// Navigates to the positive-moment form with patient context in the URI.
  static String positiveMomentFormLocation({
    required String patientId,
    required String patientName,
  }) {
    return Uri(
      path: positiveMomentForm,
      queryParameters: {
        'patientId': patientId,
        'patientName': patientName,
      },
    ).toString();
  }

  // Child
  static const String childOnboarding = '/child-onboarding';
  static const String childRegistration = '/child-step2';
  static const String childProfile = '/parent/child-profile';

  // shared
  static const String forgotPassword = '/auth/forgot-password';
  static const String videoPlayer = '/video-player';
}