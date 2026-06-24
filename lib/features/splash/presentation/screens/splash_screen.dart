import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autilog/core/constants/routes.dart';
import 'package:autilog/features/auth/bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Keep splash visible for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Wait for Firebase to finish resolving auth state if still initialising
    final authBloc = context.read<AuthBloc>();
    AuthState authState = authBloc.state;
    if (authState is AuthInitial) {
      authState = await authBloc.stream.firstWhere((s) => s is! AuthInitial);
    }
    if (!mounted) return;

    if (authState is AuthAuthenticated) {
      // ── 15-minute inactivity check across cold launches ──────────────────
      final prefs = await SharedPreferences.getInstance();
      final lastActiveMillis = prefs.getInt('lastActiveAt');

      if (lastActiveMillis == null) {
        // No activity record — fresh install or cleared data, sign out safely
        await FirebaseAuth.instance.signOut();
        if (mounted) context.go(Routes.login);
        return;
      }

      final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastActiveMillis),
      );

      if (elapsed.inMinutes >= 15) {
        // Session expired — sign out and require re-login
        await FirebaseAuth.instance.signOut();
        if (mounted) context.go(Routes.login);
        return;
      }

      // Active session within 15 minutes — route to their home screen
      if (mounted) {
        context.go(
          authState.user.role == 'therapist'
              ? Routes.therapistHome
              : Routes.parentHome,
        );
      }
    } else {
      if (mounted) context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Solid orange background ─────────────────────────────────────
          Container(color: const Color(0xFFFA8601)),

          // ── Top-right decorative circle ─────────────────────────────────
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),

          // ── Left-middle decorative circle ───────────────────────────────
          Positioned(
            top: size.height * 0.36,
            left: -55,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),

          // ── Logo + app name ─────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/autilog_logo.png',
                  width: 173,
                  height: 173,
                ),
                const SizedBox(height: 14),
                Text(
                  'AutiLog',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom page-indicator dots ──────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(i == 1 ? 1.0 : 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
