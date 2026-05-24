import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:autilog/features/splash/presentation/screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


import 'core/constants/routes.dart';
import 'core/theme/theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/shared/role_selection_screen.dart';
import 'features/auth/presentation/therapist/screens/therapist_registration_screen.dart';
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

import 'features/incident_log/presentation/screens/incident_form_screen.dart';

import 'features/auth/presentation/shared/login_screen.dart';
import 'features/auth/presentation/shared/forgot_password_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => TherapistRepository()),
        RepositoryProvider(create: (_) => PatientRepository()),
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

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;
  late final _AuthRouterNotifier _notifier;
  late final AuthBloc _authBloc;
  Timer? _inactivityTimer;

  static const _inactivityDuration = Duration(minutes: 15);

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _logoutDueToInactivity);
    // Persist last activity time for cold-launch inactivity check
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

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _notifier = _AuthRouterNotifier(_authBloc);
    _resetInactivityTimer();

  _router = GoRouter(  
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final authState = _authBloc.state;
      final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnSplash = state.matchedLocation == Routes.splash;

      // Splash handles its own navigation — never redirect away from it
      if (isOnSplash) return null;

      if (authState is AuthUnauthenticated || authState is AuthInitial) {
        return isOnAuthRoute ? null : Routes.roleSelection;
      }

      if (authState is AuthAuthenticated && isOnAuthRoute) {
        if (authState.user.role == 'therapist') {
          return Routes.therapistHome;
        } else if (authState.user.role == 'parent') {
          return Routes.childOnboarding;
        }
      }

      return null;
    },
  routes: [   
    GoRoute(
      path: Routes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.roleSelection,
      builder: (_, __) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.forgotPassword,
      builder: (_, __) => const ForgetPasswordScreen(),
    ),
    GoRoute(
      path: Routes.registerTherapist,
      builder: (_, __) => const TherapistRegistrationScreen(),
    ),
    GoRoute(
      path: Routes.therapistHome,
      builder: (_, __) => const TherapistHomeScreen(),
    ),
    GoRoute(
      path: Routes.therapistProfile,
      builder: (_, __) => const TherapistProfileOverviewScreen(),
    ),
    GoRoute(
      path: Routes.therapistProfileEdit,
      builder: (_, __) => const TherapistEditProfileScreen(),
    ),
    GoRoute(
      path: Routes.therapistPatients,
      builder: (_, __) => const PatientListScreen(),
    ),
    GoRoute(
      path: Routes.registerParent,
      builder: (_, __) => const ParentRegistrationScreen(),
    ),
    GoRoute(
      path: Routes.childOnboarding,
      builder: (_, __) => const ChildOnboardingScreen(),
    ),
    GoRoute(
      path: Routes.childRegistration,
      builder: (_, __) => const ChildRegistrationScreen(),
    ),
    GoRoute(
      path: Routes.parentHome,
      builder: (_, __) => const ParentHomeScreen(),
    ),
    GoRoute(
      path: Routes.parentProfile,
      builder: (_, __) => const ParentProfileScreen(),
    ),
    GoRoute(
      path: Routes.incidentForm,
      builder: (context, state) {
        final args = state.extra as IncidentFormArgs;
        return IncidentFormScreen(
          patientId: args.patientId,
          patientName: args.patientName,
          therapistName: args.therapistName,
        );
      },
    ),
  
  ],
);

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
      child: MaterialApp.router(
        title: 'AutiLog',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
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
