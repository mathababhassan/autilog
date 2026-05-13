import 'package:go_router/go_router.dart';

import '../constants/routes.dart';

import 'package:autilog/features/auth/presentation/shared/role_selection_screen.dart';
import 'package:autilog/features/auth/presentation/shared/login.dart';

import 'package:autilog/features/auth/presentation/parent/screens/parent_home_screen.dart';
import 'package:autilog/features/profile/therapist/presentation/screens/therapist_home_screen.dart';

import 'package:autilog/features/auth/presentation/parent/screens/parent_registration_screen.dart';

import 'package:autilog/features/auth/presentation/therapist/screens/therapist_registration_screen.dart';

final router = GoRouter(
  initialLocation: Routes.login,
  routes: [
    // ✅ Role selection
    GoRoute(
      path: Routes.roleSelection,
      builder: (_, __) => const RoleSelectionScreen(),
    ),

    // ✅ Login (WITH ROLE)
    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        final role = state.uri.queryParameters['role'];
        return LoginScreen(role: role);
      },
    ),

    // ✅ Register
    GoRoute(
      path: Routes.registerParent,
      builder: (_, __) => const ParentRegistrationScreen(),
    ),

    GoRoute(
      path: Routes.registerTherapist,
      builder: (_, __) => const TherapistRegistrationScreen(),
    ),

    // ✅ Home screens
    GoRoute(
      path: Routes.parentHome,
      builder: (_, __) => const ParentHomeScreen(),
    ),

    GoRoute(
      path: Routes.therapistHome,
      builder: (_, __) => const TherapistHomeScreen(),
    ),
  ],
);
