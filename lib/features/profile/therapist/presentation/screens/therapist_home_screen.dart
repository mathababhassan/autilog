import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../features/patients/bloc/patient_list_bloc.dart';
import '../../../../../features/patients/bloc/patient_list_event.dart';
import '../../../../../features/patients/bloc/patient_list_state.dart';
import '../../../../../features/sessions/data/session_repository.dart';
import '../../../../../shared/models/session_model.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../bloc/therapist_home_cubit.dart';
import '../../bloc/therapist_home_state.dart';
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
  late final TherapistHomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = TherapistHomeCubit(sessionRepository: SessionRepository());
    context.read<TherapistProfileBloc>().add(const TherapistProfileStarted());
    context.read<PatientListBloc>().add(const PatientListStarted());
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: BlocListener<PatientListBloc, PatientListState>(
        listener: (context, patientState) {
          if (patientState is PatientListLoaded &&
              patientState.activePatients.isNotEmpty) {
            final profileState = context.read<TherapistProfileBloc>().state;
            final uid = profileState is TherapistProfileLoaded
                ? profileState.therapist.userId
                : '';
            _homeCubit.load(
              therapistId: uid,
              patients: patientState.activePatients.where((e) => !e.$3).map((e) => e.$1).toList(),
            );
          }
        },
        child: Scaffold(
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
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

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
              Positioned(right: -28, top: 20,
                  child: _Circle(size: 130, opacity: 0.18)),
              Positioned(right: 42, top: 36,
                  child: _Circle(size: 22, opacity: 0.55)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.stars_rounded,
                            color: AppColors.textWhite, size: 22),
                        const SizedBox(width: 8),
                        Text('AutiLog',
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textWhite,
                            )),
                      ]),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.22),
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
                          color: AppColors.textWhite.withValues(alpha: 0.92))),
                  const SizedBox(height: 2),
                  Text(
                    firstName.isEmpty
                        ? 'Hello!'
                        : 'Good ${_greeting()}, Dr. $firstName',
                    style: AppTextStyles.heading1
                        .copyWith(color: AppColors.textWhite),
                  ),
                  // Stats row — only when data loaded
                  BlocBuilder<TherapistHomeCubit, TherapistHomeState>(
                    builder: (context, homeState) {
                      if (homeState is TherapistHomeLoaded) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _StatsRow(
                            sessionsToday: homeState.sessionsToday.length,
                            newLogs: homeState.newLogsCount,
                            urgentAlerts: homeState.urgentAlertsCount,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formatDate(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.sessionsToday,
    required this.newLogs,
    required this.urgentAlerts,
  });

  final int sessionsToday;
  final int newLogs;
  final int urgentAlerts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '$sessionsToday', label: 'Sessions Today')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '$newLogs', label: 'New Logs')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '$urgentAlerts', label: 'Urgent Alerts')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.primary, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.tag
                  .copyWith(color: AppColors.textPlaceholder, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientListBloc, PatientListState>(
      builder: (context, patientState) {
        final hasPatients = patientState is PatientListLoaded &&
            patientState.activePatients.isNotEmpty;
        if (!hasPatients) return _EmptyBody();
        return _DataBody();
      },
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TherapistProfileBloc, TherapistProfileState>(
      builder: (context, state) {
        final email = switch (state) {
          TherapistProfileLoaded s => s.user.email,
          TherapistProfileUpdateSuccess s => s.user.email,
          _ => null,
        };

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin, 24, AppSpacing.screenMargin, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(right: -30, top: -30,
                        child: _DecorCircle(size: 110, color: AppColors.primary, opacity: 0.12)),
                    Positioned(left: -20, bottom: -30,
                        child: _DecorCircle(size: 80, color: AppColors.secondary, opacity: 0.08)),
                    Positioned(right: 10, top: 10,
                        child: _DecorCircle(size: 18, color: AppColors.primary, opacity: 0.3)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                      child: Column(
                        children: [
                          Container(
                            width: 84, height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDefault,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                blurRadius: 14, offset: const Offset(0, 4),
                              )],
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/patient_outline.svg',
                                width: 32, height: 32,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.primary, BlendMode.srcIn),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('No patients yet',
                              style: AppTextStyles.heading1
                                  .copyWith(color: AppColors.textMain),
                              textAlign: TextAlign.center),
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
                                    Text(email,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w600,
                                        )),
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
                            onPressed: () =>
                                context.go(Routes.therapistPatients),
                            borderRadius: 999,
                            leading: SvgPicture.asset(
                              'assets/icons/patient_outline.svg',
                              width: 18, height: 18,
                              colorFilter: const ColorFilter.mode(
                                  AppColors.textWhite, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _WhatYouCanDoSection(),
            ],
          ),
        );
      },
    );
  }
}

// ─── Data state ───────────────────────────────────────────────────────────────

class _DataBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TherapistHomeCubit, TherapistHomeState>(
      builder: (context, state) {
        if (state is TherapistHomeLoading || state is TherapistHomeInitial) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state is TherapistHomeError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('Could not load data.\n${state.message}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPlaceholder),
                  textAlign: TextAlign.center),
            ),
          );
        }

        if (state is TherapistHomeLoaded) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin, 24, AppSpacing.screenMargin, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Needs Attention
                if (state.needsAttention.isNotEmpty) ...[
                  Text('Needs Attention',
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...state.needsAttention
                      .map((p) => _NeedsAttentionCard(patient: p)),
                  const SizedBox(height: 24),
                ],
                // Today's Sessions
                Text("Today's Sessions",
                    style: AppTextStyles.subtitle
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (state.sessionsToday.isEmpty)
                  _EmptySessionsCard()
                else
                  ...state.sessionsToday.map((s) => _SessionCard(session: s)),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Needs Attention card ─────────────────────────────────────────────────────

class _NeedsAttentionCard extends StatelessWidget {
  const _NeedsAttentionCard({required this.patient});
  final UrgentPatient patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE57373), width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondary20,
            child: Text(
              patient.childName.isNotEmpty
                  ? patient.childName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.secondary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.childName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 8, color: Color(0xFFE53935)),
                    const SizedBox(width: 6),
                    Text(patient.alertMessage,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textPlaceholder)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.sessionDetail, extra: session.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.secondary20,
              child: Text(
                session.childName.isNotEmpty
                    ? session.childName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.secondary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.childName,
                      style:
                          AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: AppColors.textPlaceholder),
                      const SizedBox(width: 4),
                      Text(session.formattedTimeRange,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textPlaceholder)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textPlaceholder),
                      const SizedBox(width: 4),
                      Text(session.mode,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textPlaceholder)),
                    ],
                  ),
                ],
              ),
            ),
            // Actions menu
            GestureDetector(
              onTap: () => _showHomeSessionActions(context, session),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.more_vert,
                    size: 20, color: AppColors.textSubtle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty sessions ───────────────────────────────────────────────────────────

class _EmptySessionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 32, color: AppColors.textSubtle),
          const SizedBox(height: 10),
          Text('No sessions scheduled for today',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPlaceholder),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── What You Can Do ──────────────────────────────────────────────────────────

class _WhatYouCanDoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What You Can Do Here',
            style: AppTextStyles.subtitle
                .copyWith(color: AppColors.textMain, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        _FlatRow(
          icon: SvgPicture.asset('assets/icons/patient_outline.svg',
              width: 20, height: 20,
              colorFilter: const ColorFilter.mode(
                  AppColors.secondary, BlendMode.srcIn)),
          title: 'Patient activity logs',
          body: 'Drill into any incident, video, or daily summary across all your patients.',
        ),
        const SizedBox(height: 10),
        _FlatRow(
          icon: SvgPicture.asset('assets/icons/gen_ai.svg',
              width: 20, height: 20,
              colorFilter: const ColorFilter.mode(
                  AppColors.secondary, BlendMode.srcIn)),
          title: 'AI weekly reports',
          body: "Get AI-generated summaries of each patient's week so every session is more productive.",
        ),
        const SizedBox(height: 10),
        _FlatRow(
          icon: SvgPicture.asset('assets/icons/report_outline.svg',
              width: 20, height: 20,
              colorFilter: const ColorFilter.mode(
                  AppColors.secondary, BlendMode.srcIn)),
          title: 'Customise parent tracking',
          body: 'Add your own questions to shape exactly what parents log in their daily summary.',
        ),
      ],
    );
  }
}

class _FlatRow extends StatelessWidget {
  const _FlatRow(
      {required this.icon, required this.title, required this.body});
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
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 14, offset: const Offset(0, 4),
        )],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40, height: 40,
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
              children: [
                Text(title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPlaceholder, height: 1.25)),
              ],
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
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────

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
                onTap: () => context.go(Routes.therapistSessions),
              ),
              _TabItem(
                iconOutline: 'assets/icons/report_outline.svg',
                iconFilled: 'assets/icons/report_filled.svg',
                label: 'Reports',
                onTap: () => context.go(Routes.therapistReports),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─── Home session actions ─────────────────────────────────────────────────────

void _showHomeSessionActions(BuildContext context, SessionModel session) {
  final cubit = context.read<TherapistHomeCubit>();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.edit_calendar_outlined,
                color: AppColors.secondary),
            title: Text('Reschedule',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.of(sheetCtx).pop();
              await _showHomeRescheduleSheet(context, session, cubit);
            },
          ),
          const Divider(height: 1, color: AppColors.dividerLight),
          ListTile(
            leading: const Icon(Icons.cancel_outlined, color: AppColors.error),
            title: Text('Cancel Session',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.of(sheetCtx).pop();
              await _showHomeCancelDialog(context, session, cubit);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _showHomeRescheduleSheet(
    BuildContext context, SessionModel session, TherapistHomeCubit cubit) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HomeRescheduleSheet(
      session: session,
      onConfirm: (date, time) async {
        final scheduledAt = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
        final duration = session.endTime.difference(session.scheduledAt);
        final endTime = scheduledAt.add(duration);
        await SessionRepository().rescheduleSession(
          sessionId: session.id,
          newStart: scheduledAt,
          newEnd: endTime,
        );
      },
    ),
  );
  if (result == true && context.mounted) {
    cubit.reload();
    AppSnackbar.showSuccess(context, 'Session rescheduled successfully.');
  }
}

Future<void> _showHomeCancelDialog(
    BuildContext context, SessionModel session, TherapistHomeCubit cubit) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cancel Session'),
      content: Text(
          'Are you sure you want to cancel the session with ${session.childName}?\n\nThe parent will be notified.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Keep Session'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancel Session'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    try {
      await SessionRepository().cancelSession(session.id);
      if (context.mounted) {
        cubit.reload();
        AppSnackbar.showSuccess(context, 'Session cancelled.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'Could not cancel. Please try again.');
      }
    }
  }
}

class _HomeRescheduleSheet extends StatefulWidget {
  const _HomeRescheduleSheet(
      {required this.session, required this.onConfirm});
  final SessionModel session;
  final Future<void> Function(DateTime, TimeOfDay) onConfirm;

  @override
  State<_HomeRescheduleSheet> createState() => _HomeRescheduleSheetState();
}

class _HomeRescheduleSheetState extends State<_HomeRescheduleSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.session.scheduledAt;
    _selectedTime = TimeOfDay.fromDateTime(widget.session.scheduledAt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.secondary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.secondary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _fmtDate(DateTime d) {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]} ${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final s = widget.session;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Reschedule Session',
              style:
                  AppTextStyles.heading1.copyWith(color: AppColors.textMain)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text('${s.childName} · ${s.type}',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.textMain),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                '${s.formattedDateShort} · ${TimeOfDay.fromDateTime(s.scheduledAt).format(context)} · ${s.mode}',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('New Date',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textMain)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDefault,
                border: Border.all(color: AppColors.borderInactive),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 10),
                Text(_fmtDate(_selectedDate),
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textMain)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('New Time',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textMain)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDefault,
                border: Border.all(color: AppColors.borderInactive),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.access_time_outlined,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 10),
                Text(_fmtTime(_selectedTime),
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textMain)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text('The parent will be notified of the change.',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await widget.onConfirm(_selectedDate, _selectedTime);
                        if (mounted) Navigator.of(context).pop(true);
                      } catch (_) {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Reschedule & Notify Parent',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary, fontWeight: FontWeight.w700)),
          ),
        ],
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
          SvgPicture.asset(asset, width: 22, height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
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