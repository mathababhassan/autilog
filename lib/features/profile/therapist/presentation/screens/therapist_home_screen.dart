import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../bloc/therapist_profile_bloc.dart';
import '../../bloc/therapist_profile_event.dart';
import '../../bloc/therapist_profile_state.dart';
import '../widgets/therapist_profile_sheet.dart';

class TherapistHomeScreen extends StatefulWidget {
  const TherapistHomeScreen({super.key});

  @override
  State<TherapistHomeScreen> createState() => _TherapistHomeScreenState();
}

class _TherapistHomeScreenState extends State<TherapistHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TherapistProfileBloc>().add(const TherapistProfileStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeader(
                    onAvatarTap: () => showTherapistProfileSheet(context),
                  ),
                  _HomeBody(),
                ],
              ),
            ),
          ),
          const _TabBar(),
        ],
      ),
    );
  }
}

// ─── Orange header ───────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onAvatarTap});

  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    return BlocBuilder<TherapistProfileBloc, TherapistProfileState>(
      builder: (context, state) {
        final firstName = _firstName(state);
        return Container(
          padding: EdgeInsets.fromLTRB(22, topPadding + 14, 22, 22),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative circles
              Positioned(
                right: -28,
                top: 20,
                child: _Circle(size: 130, opacity: 0.18),
              ),
              Positioned(
                right: 42,
                top: 36,
                child: _Circle(size: 22, opacity: 0.55),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: AppColors.textWhite, size: 22),
                          const SizedBox(width: 8),
                          Text('AutiLog',
                              style: AppTextStyles.subtitle.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textWhite,
                              )),
                        ],
                      ),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha:0.22),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: AppColors.textWhite, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(dateStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textWhite.withValues(alpha:0.92),
                      )),
                  const SizedBox(height: 2),
                  Text(
                    firstName.isEmpty
                        ? 'Hello!'
                        : 'Hello, Dr. $firstName',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Share your email with parents so they can send you patient requests.",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textWhite.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _firstName(TherapistProfileState state) {
    final String fullName;
    if (state is TherapistProfileLoaded) {
      fullName = state.therapist.name;
    } else if (state is TherapistProfileUpdateSuccess) {
      fullName = state.therapist.name;
    } else {
      return '';
    }
    final parts =
        fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? fullName : parts.first;
  }

  String _formatDate(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha:opacity),
      ),
    );
  }
}

// ─── Scrollable body ─────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin, 24, AppSpacing.screenMargin, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(),
          const SizedBox(height: 24),
          _WhatYouCanDoSection(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative shapes
          Positioned(
            right: -30,
            top: -30,
            child: _DecorCircle(size: 110, color: AppColors.primary, opacity: 0.12),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: _DecorCircle(size: 80, color: AppColors.secondary, opacity: 0.08),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: _DecorCircle(size: 18, color: AppColors.primary, opacity: 0.3),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: BlocBuilder<TherapistProfileBloc, TherapistProfileState>(
              builder: (context, state) {
                final email = switch (state) {
                  TherapistProfileLoaded s => s.user.email,
                  TherapistProfileUpdateSuccess s => s.user.email,
                  _ => null,
                };

                return Column(
                  children: [
                    // Icon box
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDefault,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/patient_outline.svg',
                          width: 32,
                          height: 32,
                          colorFilter: const ColorFilter.mode(
                              AppColors.primary, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No patients yet',
                      style: AppTextStyles.heading1
                          .copyWith(color: AppColors.textMain),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Parents add you by sending a request to your AutiLog email. Share your email with a parent to get started.",
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPlaceholder, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary20,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mail_outline,
                                  size: 14, color: AppColors.secondary),
                              const SizedBox(width: 6),
                              Text(
                                email,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy_rounded,
                                  size: 13, color: AppColors.secondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    AppPrimaryButton(
                      label: 'View Patients',
                      onPressed: () => context.go(Routes.therapistPatients),
                      borderRadius: 999,
                      leading: SvgPicture.asset(
                        'assets/icons/patient_outline.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                            AppColors.textWhite, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle(
      {required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha:opacity),
      ),
    );
  }
}

class _WhatYouCanDoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What You Can Do Here',
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.textMain,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        _FlatRow(
          icon: SvgPicture.asset(
            'assets/icons/patient_outline.svg',
            width: 20,
            height: 20,
            colorFilter:
                const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn),
          ),
          title: 'Patient activity logs',
          body: 'Drill into any incident, video, or daily summary across all your patients.',
        ),
        const SizedBox(height: 10),
        _FlatRow(
          icon: SvgPicture.asset('assets/icons/gen_ai.svg',
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn)),
          title: 'AI weekly reports',
          body: 'Get AI-generated summaries of each patient\'s week so every session is more productive.',
        ),
        const SizedBox(height: 10),
        _FlatRow(
          icon: SvgPicture.asset('assets/icons/report_outline.svg',
              width: 20, height: 20,
              colorFilter:
                  const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn)),
          title: 'Customise parent tracking',
          body: 'Add your own questions to shape exactly what parents log in their daily summary.',
        ),
      ],
    );
  }
}

class _FlatRow extends StatelessWidget {
  const _FlatRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final Widget icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary20,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPlaceholder,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stub tab bar ─────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TabItem(
                iconOutline: 'assets/icons/home_outline.svg',
                iconFilled: 'assets/icons/home_filled.svg',
                label: 'Home',
                active: true,
              ),
              _TabItem(
                iconOutline: 'assets/icons/patient_outline.svg',
                iconFilled: 'assets/icons/patient_filled.svg',
                label: 'Patients',
                onTap: () => context.go(Routes.therapistPatients),
              ),
              _TabItem(
                iconOutline: 'assets/icons/session_outline.svg',
                iconFilled: 'assets/icons/session_filled.svg',
                label: 'Sessions',
              ),
              _TabItem(
                iconOutline: 'assets/icons/report_outline.svg',
                iconFilled: 'assets/icons/report_filled.svg',
                label: 'Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.iconOutline,
    this.iconFilled,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String iconOutline;
  final String? iconFilled;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMain;
    final asset = active ? (iconFilled ?? iconOutline) : iconOutline;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            asset,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.tag.copyWith(
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              )),
        ],
      ),
    );
  }
}
