import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/session_model.dart';
import '../../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../../patients/data/patient_repository.dart';
import '../../../bloc/session_list_bloc.dart';
import '../../../bloc/session_list_event.dart';
import '../../../bloc/session_list_state.dart';
import '../../../data/session_repository.dart';

// ─── Screen (provides the BLoC) ───────────────────────────────────────────────

class SessionListScreen extends StatelessWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionListBloc(
        sessionRepository: SessionRepository(),
        patientRepository: context.read<PatientRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..add(const SessionListStarted()),
      child: const _SessionListView(),
    );
  }
}

class _SessionListView extends StatelessWidget {
  const _SessionListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionListBloc, SessionListState>(
      listenWhen: (prev, curr) =>
          curr is SessionListLoaded &&
          curr.actionStatus != SessionListActionStatus.idle,
      listener: (context, state) {
        if (state is! SessionListLoaded || state.actionMessage == null) return;
        if (state.actionStatus == SessionListActionStatus.success) {
          AppSnackbar.showSuccess(context, state.actionMessage!);
        } else if (state.actionStatus == SessionListActionStatus.error) {
          AppSnackbar.showError(context, state.actionMessage!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceDefault,
        appBar: _buildAppBar(context),
        floatingActionButton: _AddSessionButton(
          onTap: () => _showSchedulingPlaceholder(context),
        ),
        bottomNavigationBar: const _TabBar(),
        body: BlocBuilder<SessionListBloc, SessionListState>(
        builder: (context, state) {
          if (state is SessionListLoading || state is SessionListInitial) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }

          if (state is SessionListError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<SessionListBloc>()
                  .add(const SessionListRefreshRequested()),
            );
          }

          final loaded = state as SessionListLoaded;

          // Zero sessions for the whole account → full-screen empty.
          if (!loaded.hasAnySessions) {
            return _EmptyState(
              onSchedule: () => _showSchedulingPlaceholder(context),
            );
          }

          return _LoadedContent(state: loaded);
        },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceDefault,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 56,
      titleSpacing: 0,
      leading: GestureDetector(
        onTap: () => context.go(Routes.therapistHome),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xl),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/icon_back.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                  AppColors.textMain, BlendMode.srcIn),
            ),
          ),
        ),
      ),
      centerTitle: false,
      title: Text('Sessions',
          style: AppTextStyles.heading1.copyWith(color: AppColors.textMain)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.borderInactive),
      ),
    );
  }
}

// ─── Loaded content (filter + Upcoming + Past) ────────────────────────────────

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({required this.state});

  final SessionListLoaded state;

  @override
  Widget build(BuildContext context) {
    final upcoming = state.upcoming;
    final past = state.past;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient filter
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
            child: _PatientFilter(state: state),
          ),
          const SizedBox(height: AppSpacing.xl2),

          // Upcoming section — always shown (heading + cards or inline empty).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _SectionHeader(title: 'Upcoming', count: upcoming.length),
          ),
          const SizedBox(height: AppSpacing.md),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _InlineEmpty(
                message: state.isFiltered
                    ? 'No upcoming sessions for this patient'
                    : 'No upcoming sessions',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  for (final session in upcoming) ...[
                    _UpcomingSessionCard(
                      session: session,
                      onTap: () async {
                        await context.push(Routes.sessionDetail,
                            extra: session.id);
                        if (context.mounted) {
                          context
                              .read<SessionListBloc>()
                              .add(const SessionListRefreshRequested());
                        }
                      },
                      onMore: () => _showSessionActions(context, session),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),

          // Past section — only when there are past sessions to show.
          if (past.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _SectionHeader(title: 'Past', count: past.length),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  for (final session in past) ...[
                    _PastSessionCard(
                      session: session,
                      onTap: () async {
                        await context.push(Routes.sessionDetail,
                            extra: session.id);
                        if (context.mounted) {
                          context
                              .read<SessionListBloc>()
                              .add(const SessionListRefreshRequested());
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Patient filter dropdown ──────────────────────────────────────────────────

class _PatientFilter extends StatelessWidget {
  const _PatientFilter({required this.state});

  final SessionListLoaded state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedPatient;
    final label = selected?.name ?? 'All Patients';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Patient',
            style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled)),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => _showPatientPicker(context, state),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              border: Border.all(color: AppColors.secondary, width: 1.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary20,
                  ),
                  alignment: Alignment.center,
                  child: const _SvgIcon('ic_people_filter.svg',
                      size: 15, color: AppColors.secondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const _SvgIcon('ic_chevron_down.svg',
                    size: 22, color: AppColors.textMain),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPatientPicker(BuildContext context, SessionListLoaded state) {
    final bloc = context.read<SessionListBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.sheetRadius)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            const _SheetGrabber(),
            const SizedBox(height: AppSpacing.sm),
            _PatientPickerTile(
              label: 'All Patients',
              selected: state.selectedChildId == null,
              onTap: () {
                Navigator.of(context).pop();
                bloc.add(const SessionPatientFilterChanged(null));
              },
            ),
            for (final patient in state.patients)
              _PatientPickerTile(
                label: patient.name,
                selected: state.selectedChildId == patient.childId,
                onTap: () {
                  Navigator.of(context).pop();
                  bloc.add(SessionPatientFilterChanged(patient.childId));
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _PatientPickerTile extends StatelessWidget {
  const _PatientPickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: selected ? AppColors.secondary : AppColors.textMain,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.secondary, size: 20)
          : null,
    );
  }
}

// ─── Section header (title + count badge) ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.11,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Upcoming session card ────────────────────────────────────────────────────

class _UpcomingSessionCard extends StatelessWidget {
  const _UpcomingSessionCard({
    required this.session,
    required this.onTap,
    required this.onMore,
  });

  final SessionModel session;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          border: Border.all(color: AppColors.borderInactive, width: 1.18),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name | status pill + more
            Row(
              children: [
                _Avatar(name: session.childName),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    session.childName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const _StatusPill(status: 'upcoming'),
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: onMore,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    child: _SvgIcon('ic_more.svg',
                        size: 20, color: AppColors.textDisabled),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
            const SizedBox(height: AppSpacing.sm),
            // Meta rows
            _MetaRow(
              asset: 'ic_calendar.svg',
              text: _formatDateTime(session.scheduledAt),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              asset: 'ic_target.svg',
              text: '${session.type} · ${_durationMinutes(session)} min',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ModeIndicator(mode: session.mode),
          ],
        ),
      ),
    );
  }
}

// ─── Past session card ────────────────────────────────────────────────────────

class _PastSessionCard extends StatelessWidget {
  const _PastSessionCard({required this.session, required this.onTap});

  final SessionModel session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          border: Border.all(color: AppColors.borderInactive, width: 1.18),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: avatar + name | status pill
                  Row(
                    children: [
                      _Avatar(name: session.childName),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          session.childName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      _StatusPill(
                        status:
                            session.isPastDue ? 'needs_review' : session.status,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(
                      height: 1, thickness: 1, color: AppColors.dividerLight),
                  const SizedBox(height: AppSpacing.sm),
                  // Date + type on the left, mode on the right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetaRow(
                              asset: 'ic_calendar.svg',
                              text: _formatDateTime(session.scheduledAt),
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _MetaRow(
                              asset: 'ic_target.svg',
                              text:
                                  '${session.type} · ${_durationMinutes(session)} min',
                              color: AppColors.textDisabled,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ModeIndicator(mode: session.mode),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Chevron floats vertically centered on the card's right edge,
            // matching the Figma SessionCard frame (node 1134:5297).
            const _SvgIcon('ic_chevron_right.svg',
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

// ─── Shared card pieces ───────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary20,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case 'completed':
        bg = AppColors.success20;
        fg = AppColors.success;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = AppColors.error20;
        fg = AppColors.error;
        label = 'Cancelled';
        break;
      case 'needs_review':
        // Neutral grey — a nudge to resolve, not a success/error outcome.
        bg = AppColors.inputFill;
        fg = AppColors.textDisabled;
        label = 'Needs review';
        break;
      default:
        bg = AppColors.secondary20;
        fg = AppColors.secondary;
        label = 'Upcoming';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.asset,
    required this.text,
    this.color = AppColors.textPlaceholder,
  });

  final String asset;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SvgIcon(asset, size: 14, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  const _ModeIndicator({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final isVirtual = mode == 'Virtual';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SvgIcon(
          isVirtual ? 'ic_video.svg' : 'ic_location.svg',
          size: 14,
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          mode,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

// ─── Quick-actions bottom sheet (upcoming only) ───────────────────────────────

void _showSessionActions(BuildContext context, SessionModel session) {
  final bloc = context.read<SessionListBloc>();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceModal,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSpacing.sheetRadius)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          const _SheetGrabber(),
          const SizedBox(height: AppSpacing.lg),

          // Context header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            padding: const EdgeInsets.all(AppSpacing.md),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '${session.childName} · ${session.type}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  '${_formatDateTime(session.scheduledAt)} · ${session.mode}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _ActionRow(
            leading: const _SvgIcon('ic_doc.svg',
                size: 20, color: AppColors.secondary),
            label: 'View Details',
            color: AppColors.secondary,
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await context.push(Routes.sessionDetail, extra: session.id);
              if (context.mounted) {
                context
                    .read<SessionListBloc>()
                    .add(const SessionListRefreshRequested());
              }
            },
          ),
          _ActionRow(
            leading: const Icon(Icons.check_circle_outline,
                size: 20, color: AppColors.success),
            label: 'Mark as Completed',
            color: AppColors.success,
            onTap: () async {
              Navigator.of(sheetContext).pop();
              final confirmed = await showAppConfirmDialog(
                context: context,
                title: 'Mark as completed?',
                message:
                    "This moves ${session.childName}'s session to your past sessions.",
                confirmLabel: 'Mark Completed',
                confirmColor: AppColors.success,
              );
              if (confirmed) bloc.add(SessionMarkedCompleted(session.id));
            },
          ),
          _ActionRow(
            leading: const _SvgIcon('ic_reschedule.svg',
                size: 20, color: AppColors.secondary),
            label: 'Reschedule',
            color: AppColors.secondary,
            onTap: () {
              Navigator.of(sheetContext).pop();
              AppSnackbar.showSuccess(
                  context, 'Rescheduling is coming soon.');
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
          ),
          _ActionRow(
            leading: const _SvgIcon('ic_close.svg',
                size: 20, color: AppColors.error),
            label: 'Cancel Session',
            color: AppColors.error,
            onTap: () {
              Navigator.of(sheetContext).pop();
              AppSnackbar.showSuccess(
                  context, 'Cancelling sessions is coming soon.');
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () => Navigator.of(sheetContext).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: Text(
                'Close',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.leading,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.dividerLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Renders an SVG from `assets/icons/`, tinted to [color] and sized to [size].
class _SvgIcon extends StatelessWidget {
  const _SvgIcon(this.asset, {required this.size, required this.color});

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$asset',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

// ─── Empty / inline-empty / error ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSchedule});

  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.surfaceDefault,
                borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1FFA8601),
                    offset: Offset(0, 4),
                    blurRadius: 7,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const _SvgIcon('ic_calendar_lg.svg',
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No sessions yet',
              style: AppTextStyles.heading1.copyWith(color: AppColors.textMain),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Schedule your first session to start tracking '
              'appointments with your patients.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 13, color: AppColors.textPlaceholder),
            ),
            const SizedBox(height: AppSpacing.xl2),
            AppPrimaryButton(label: 'Schedule Session', onPressed: onSchedule),
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_outlined,
              size: 28, color: AppColors.textPlaceholder),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ─── Add-session FAB ──────────────────────────────────────────────────────────

class _AddSessionButton extends StatelessWidget {
  const _AddSessionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        alignment: Alignment.center,
        child: const _SvgIcon('ic_add.svg', size: 31, color: AppColors.textWhite),
      ),
    );
  }
}

// ─── Bottom tab bar ───────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: AppColors.dividerLight, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              _TabItem(
                iconOutline: 'assets/icons/home_outline.svg',
                iconFilled: 'assets/icons/home_filled.svg',
                label: 'Home',
                onTap: () => context.go(Routes.therapistHome),
              ),
              _TabItem(
                iconOutline: 'assets/icons/patient_outline.svg',
                iconFilled: 'assets/icons/patient_filled.svg',
                label: 'Patients',
                onTap: () => context.go(Routes.therapistPatients),
              ),
              const _TabItem(
                iconOutline: 'assets/icons/session_outline.svg',
                iconFilled: 'assets/icons/session_filled.svg',
                label: 'Sessions',
                active: true,
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
    final iconColor = active ? AppColors.primary : Colors.black;
    final asset = active ? (iconFilled ?? iconOutline) : iconOutline;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              asset,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: active ? AppColors.primary : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

void _showSchedulingPlaceholder(BuildContext context) {
  AppSnackbar.showSuccess(context, 'Session scheduling is coming soon.');
}

int _durationMinutes(SessionModel session) =>
    session.endTime.difference(session.scheduledAt).inMinutes;

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "Fri, 12 Jun · 2:00 PM"
String _formatDateTime(DateTime dt) {
  final weekday = _weekdays[dt.weekday - 1];
  final month = _months[dt.month - 1];
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$weekday, ${dt.day} $month · $hour12:$minute $period';
}
