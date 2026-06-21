import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autilog/features/splash/presentation/screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/routes.dart';
import 'core/services/push_service.dart';
import 'core/theme/theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/shared/role_selection_screen.dart';
import 'features/auth/presentation/therapist/screens/therapist_registration_screen.dart';
import 'features/patients/presentation/therapist/screens/patient_details_screen.dart';
import 'features/auth/presentation/parent/screens/parent_registration_screen.dart';
import 'features/auth/presentation/parent/screens/child_onboarding_screen.dart';
import 'features/auth/presentation/parent/screens/child_registration_screen.dart';
import 'features/auth/presentation/parent/screens/parent_home_screen.dart';
import 'features/auth/presentation/parent/screens/parent_profile_screen.dart';
import 'features/patients/bloc/patient_list_bloc.dart';
import 'features/patients/data/patient_repository.dart';
import 'features/patients/presentation/therapist/screens/patient_list_screen.dart';
import 'features/profile/therapist/bloc/therapist_profile_bloc.dart';
import 'features/profile/therapist/data/therapist_repository.dart';
import 'features/profile/therapist/presentation/screens/therapist_edit_profile_screen.dart';
import 'features/profile/therapist/presentation/screens/therapist_home_screen.dart';
import 'features/profile/therapist/presentation/screens/therapist_profile_overview_screen.dart';
import 'features/sessions/presentation/therapist/screens/schedule_session_screen.dart';
import 'features/sessions/presentation/therapist/screens/session_detail_screen.dart';
import 'features/sessions/presentation/therapist/screens/session_list_screen.dart';
import 'features/incident_log/presentation/screens/incident_detail_screen.dart';
import 'features/incident_log/presentation/screens/incident_form_screen.dart';
import 'features/daily_log/presentation/screens/daily_summary_screen.dart';
import 'features/daily_log/presentation/screens/daily_summary_detail_screen.dart';
import 'features/positive_moment/positive_moment_route_args.dart';
import 'features/positive_moment/presentation/screens/positive_moment_detail_screen.dart';
import 'features/positive_moment/presentation/screens/positive_moment_form_screen.dart';
import 'features/video_player/presentation/screens/video_player_screen.dart';
import 'features/ai_insights/presentation/screens/ai_insights_screen.dart';
import 'features/log_history/presentation/screens/log_history_screen.dart';
import 'features/auth/presentation/shared/login_screen.dart';
import 'features/auth/presentation/shared/forgot_password_screen.dart';
import 'features/child_profile/bloc/child_profile_bloc.dart';
import 'features/child_profile/bloc/child_profile_event.dart';
import 'features/child_profile/data/child_profile_repository.dart';
import 'features/child_profile/presentation/screens/child_profile_screen.dart';
import 'features/sessions/presentation/parent/screens/parent_sessions_screen.dart';
import 'features/sessions/presentation/therapist/screens/session_notes_form_screen.dart';
import 'features/sessions/presentation/therapist/screens/session_notes_edit_screen.dart';
import 'shared/models/session_model.dart';
import 'features/auth/presentation/parent/screens/parent_edit_profile_screen.dart';
import 'features/auth/presentation/parent/screens/child_edit_screen.dart';
import 'features/patients/presentation/therapist/screens/log_review_screen.dart';
import 'features/profile/therapist/presentation/screens/therapist_reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => TherapistRepository()),
        RepositoryProvider(create: (_) => PatientRepository()),
        RepositoryProvider(create: (_) => ChildProfileRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const AuthStarted()),
          ),
          BlocProvider(
            create: (context) => TherapistProfileBloc(
              therapistRepository: context.read<TherapistRepository>(),
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => PatientListBloc(
              patientRepository: context.read<PatientRepository>(),
              authRepository: context.read<AuthRepository>(),
            ),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

Future<bool> _checkIfParentHasChildren(String parentId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  } catch (_) {
    return false;
  }
}


class _AppViewState extends State<_AppView> {
  late final GoRouter _router;
  late final _AuthRouterNotifier _notifier;
  late final AuthBloc _authBloc;
  Timer? _inactivityTimer;

  static const _inactivityDuration = Duration(minutes: 15);

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _logoutDueToInactivity);
    unawaited(
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setInt(
          'lastActiveAt',
          DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    );
  }

  void _logoutDueToInactivity() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      context.read<AuthRepository>().logout();
    }
  }

  /// Called when a push notification is tapped. For now it brings the user into
  /// their home; per-target deep-linking (decode data['target'] JSON → route)
  /// can be added once the notifications inbox and per-screen args are settled.
  Map<String, dynamic>? _pendingNotification;

  void _handleNotificationOpen(Map<String, dynamic> data) {
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      // Tapped from a terminated state before auth resolved — replay on login.
      _pendingNotification = data;
      return;
    }
    _router.go(
      authState.user.role == 'therapist'
          ? Routes.therapistHome
          : Routes.parentHome,
    );
  }

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _notifier = _AuthRouterNotifier(_authBloc);
    _resetInactivityTimer();

    _router = GoRouter(
      refreshListenable: _notifier,
      initialLocation: Routes.splash,
      redirect: (context, state) async {
        final authState = _authBloc.state;
        final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
        final isOnSplash = state.matchedLocation == Routes.splash;

        if (isOnSplash) return null;

        if (authState is AuthUnauthenticated || authState is AuthInitial) {
          return isOnAuthRoute ? null : Routes.login;
        }

        if (authState is AuthAuthenticated && isOnAuthRoute) {
          if (authState.user.role == 'therapist') {
            return Routes.therapistHome;
          } else if (authState.user.role == 'parent') {
            final hasChildren = await _checkIfParentHasChildren(authState.user.userId);
            return hasChildren ? Routes.parentHome : Routes.childOnboarding;
          }
        }

        return null;
      },
      routes: [
        GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: Routes.roleSelection, builder: (_, __) => const RoleSelectionScreen()),
        GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: Routes.forgotPassword, builder: (_, __) => const ForgetPasswordScreen()),
        GoRoute(path: Routes.registerTherapist, builder: (_, __) => const TherapistRegistrationScreen()),
        GoRoute(path: Routes.therapistHome, builder: (_, __) => const TherapistHomeScreen()),
        GoRoute(path: Routes.therapistProfile, builder: (_, __) => const TherapistProfileOverviewScreen()),
        GoRoute(path: Routes.therapistProfileEdit, builder: (_, __) => const TherapistEditProfileScreen()),
        GoRoute(path: Routes.therapistPatients, builder: (_, __) => const PatientListScreen()),
        GoRoute(path: Routes.therapistSessions, builder: (_, __) => const SessionListScreen()),
        GoRoute(path: Routes.scheduleSession, builder: (_, __) => const ScheduleSessionScreen()),
        GoRoute(
          path: Routes.sessionDetail,
          builder: (context, state) {
            final sessionId = state.extra as String?;
            if (sessionId == null) return const SizedBox.shrink();
            return SessionDetailScreen(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: Routes.patientDetails,
          builder: (context, state) {
            final args = state.extra as PatientDetailArgs;
            return PatientDetailsScreen(args: args);
          },
        ),
        GoRoute(
          path: Routes.logReview,
          builder: (context, state) {
            final args = state.extra as LogReviewArgs;
            return LogReviewScreen(args: args);
          },
        ),
        GoRoute(
          path: Routes.therapistReports,
          builder: (_, __) => const TherapistReportsScreen(),
        ),
        GoRoute(path: Routes.registerParent, builder: (_, __) => const ParentRegistrationScreen()),
        GoRoute(path: Routes.childOnboarding, builder: (_, __) => const ChildOnboardingScreen()),
        GoRoute(
          path: Routes.childRegistration,
          builder: (_, state) => ChildRegistrationScreen(
            fromProfile: state.uri.queryParameters['from'] == 'profile',
          ),
        ),
        GoRoute(path: Routes.parentHome, builder: (_, __) => const ParentHomeScreen()),
        GoRoute(path: Routes.parentProfile, builder: (_, __) => const ParentProfileScreen()),
        GoRoute(
          path: Routes.childProfile,
          builder: (context, state) {
            final args = state.extra as ChildProfileArgs?;
            if (args == null) return const SizedBox.shrink();
            return BlocProvider(
              create: (_) => ChildProfileBloc(
                repository: context.read<ChildProfileRepository>(),
              )..add(ChildProfileStarted(
                  parentId: args.parentId,
                  childId: args.childId,
                )),
              child: ChildProfileScreen(args: args),
            );
          },
        ),
        GoRoute(
          path: Routes.incidentForm,
          builder: (context, state) {
            final args = state.extra as IncidentFormArgs?;
            if (args == null) return const SizedBox.shrink();
            return IncidentFormScreen(
              patientId: args.patientId,
              patientName: args.patientName,
              therapistName: args.therapistName,
            );
          },
        ),
        GoRoute(
          path: Routes.incidentDetail,
          builder: (context, state) {
            final args = state.extra as IncidentDetailArgs?;
            if (args == null) return const SizedBox.shrink();
            return IncidentDetailScreen(args: args);
          },
        ),
        GoRoute(
          path: Routes.dailySummary,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            final parentId = args['parentId'] as String? ?? '';
            final childId = args['childId'] as String? ?? '';
            final childName = args['childName'] as String? ?? '';
            return DailySummaryScreen(
              parentId: parentId,
              childId: childId,
              childName: childName,
            );
          },
        ),
        GoRoute(
          path: Routes.dailySummaryDetail,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return DailySummaryDetailScreen(
              summaryId: args['summaryId'] as String? ?? '',
              parentId: args['parentId'] as String? ?? '',
              childId: args['childId'] as String? ?? '',
              childName: args['childName'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: Routes.logHistory,
          builder: (context, state) {
            final childId = state.extra as String? ?? '';
            return LogHistoryScreen(childId: childId);
          },
        ),
        GoRoute(
          path: Routes.aiInsights,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            final childId = args['childId'] as String? ?? '';
            final childName = args['childName'] as String? ?? '';
            return AIInsightsScreen(
              childId: childId,
              childName: childName,
            );
          },
        ),
        GoRoute(
  path: Routes.parentSessions,
  builder: (context, state) {
    final args = state.extra as Map<String, dynamic>? ?? {};
    return ParentSessionsScreen(
      childId: args['childId'] as String? ?? '',
      childName: args['childName'] as String? ?? '',
    );
  },
),
        GoRoute(
          path: Routes.parentProfileEdit,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return ParentEditProfileScreen(
              name: args['name'] as String? ?? '',
              phone: args['phone'] as String? ?? '',
              gender: args['gender'] as String? ?? '',
              email: args['email'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: Routes.childEdit,
          builder: (context, state) {
            final args = state.extra as ChildEditArgs?;
            if (args == null) return const SizedBox.shrink();
            return ChildEditScreen(args: args);
          },
        ),
        GoRoute(
          path: Routes.sessionNotesAdd,
          builder: (context, state) {
            final session = state.extra as SessionModel?;
            if (session == null) return const SizedBox.shrink();
            return SessionNotesFormScreen(session: session);
          },
        ),
        GoRoute(
          path: Routes.sessionNotesEdit,
          builder: (context, state) {
            final session = state.extra as SessionModel?;
            if (session == null) return const SizedBox.shrink();
            return SessionNotesEditScreen(session: session);
          },
        ),
       GoRoute(
        path: Routes.positiveMomentForm,
        builder: (context, state) {
          final args = state.extra is PositiveMomentFormArgs
              ? state.extra! as PositiveMomentFormArgs
              : positiveMomentFormArgsFromUri(state.uri);
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Missing patient for positive moment log')),
            );
          }
          return PositiveMomentFormScreen(
            patientId: args.patientId,
            patientName: args.patientName,
            existingMoment: args.existingMoment,
          );
        },
      ),
        GoRoute(
          path: Routes.positiveMomentDetail,
          builder: (context, state) {
            final args = state.extra as PositiveMomentDetailArgs?;
            if (args == null) return const SizedBox.shrink();
            return PositiveMomentDetailScreen(args: args);
          },
        ),
        GoRoute(
          path: Routes.videoPlayer,
          builder: (context, state) {
            final videoUrl = state.extra as String?;
            if (videoUrl == null) return const SizedBox.shrink();
            return VideoPlayerScreen(videoUrl: videoUrl);
          },
        ),
      ],
    );

    // Wire push handlers after _router exists — tap navigation uses it.
    PushService.instance.attachHandlers(onOpen: _handleNotificationOpen);
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _notifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      child: BlocListener<AuthBloc, AuthState>(
        // Register this device for push once, on each login transition.
        listenWhen: (prev, curr) =>
            curr is AuthAuthenticated && prev is! AuthAuthenticated,
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            PushService.instance.register(
              uid: state.user.userId,
              role: state.user.role,
            );
            // Replay a notification tapped before auth had resolved.
            final pending = _pendingNotification;
            if (pending != null) {
              _pendingNotification = null;
              _handleNotificationOpen(pending);
            }
          }
        },
        child: MaterialApp.router(
          title: 'AutiLog',
          theme: AppTheme.light,
          routerConfig: _router,
          scaffoldMessengerKey: PushService.instance.messengerKey,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}