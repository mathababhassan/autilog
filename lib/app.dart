import 'dart:async';

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
import 'features/profile/therapist/bloc/therapist_profile_bloc.dart';
import 'features/profile/therapist/data/therapist_repository.dart';
import 'features/profile/therapist/presentation/screens/therapist_edit_profile_screen.dart';
import 'features/profile/therapist/presentation/screens/therapist_home_screen.dart';
import 'features/profile/therapist/presentation/screens/therapist_profile_overview_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => TherapistRepository()),
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

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _notifier = _AuthRouterNotifier(_authBloc);

    _router = GoRouter(
      refreshListenable: _notifier,
      initialLocation: Routes.roleSelection,
      redirect: (context, state) {
        final authState = _authBloc.state;
        final isOnAuthRoute = state.matchedLocation.startsWith('/auth');

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
        // Shared
        GoRoute(
          path: Routes.roleSelection,
          builder: (_, __) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Login Screen')),
          ),
        ),

        // Therapist
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

        // Parent
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
      ],
    );
  }

  @override
  void dispose() {
    _notifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AutiLog',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
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