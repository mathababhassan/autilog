import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/routes.dart';
import 'core/theme/theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/therapist/screens/therapist_registration_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AuthRepository(),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        )..add(const AuthStarted()),
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
      initialLocation: Routes.login,
      redirect: (context, state) {
        final authState = _authBloc.state;
        final isOnAuthRoute = state.matchedLocation.startsWith('/auth');

        // Unauthenticated users are always sent to login.
        if (authState is AuthUnauthenticated || authState is AuthInitial) {
          return isOnAuthRoute ? null : Routes.login;
        }

        // Authenticated users are redirected away from auth screens to their home.
        if (authState is AuthAuthenticated && isOnAuthRoute) {
          return authState.user.role == 'therapist'
              ? Routes.therapistHome
              : Routes.parentHome;
        }

        return null; // No redirect needed.
      },
      routes: [
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Login Screen')),
          ),
        ),
        GoRoute(
          path: Routes.registerTherapist,
          builder: (_, _) => const TherapistRegistrationScreen(),
        ),
        GoRoute(
          path: Routes.therapistHome,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Therapist Home')),
          ),
        ),
        GoRoute(
          path: Routes.parentHome,
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Parent Home')),
          ),
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

/// Converts AuthBloc state changes into GoRouter refresh notifications.
/// GoRouter calls [redirect] every time [notifyListeners] fires.
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
