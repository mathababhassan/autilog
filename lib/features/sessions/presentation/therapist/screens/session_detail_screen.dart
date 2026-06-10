import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/child_model.dart';
import '../../../../../shared/models/session_model.dart';
import '../../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../bloc/session_detail_bloc.dart';
import '../../../bloc/session_detail_event.dart';
import '../../../bloc/session_detail_state.dart';
import '../../../data/session_repository.dart';
import '../../../../patients/presentation/therapist/screens/patient_details_screen.dart';
import '../widgets/cancel_session_sheet.dart';
import '../widgets/reschedule_session_sheet.dart';
import 'session_notes_form_screen.dart';
import 'session_notes_edit_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionDetailBloc(repository: SessionRepository())
        ..add(SessionDetailStarted(sessionId: sessionId)),
      child: _SessionDetailView(sessionId: sessionId),
    );
  }
}

class _SessionDetailView extends StatelessWidget {
  const _SessionDetailView({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionDetailBloc, SessionDetailState>(
      listenWhen: (prev, curr) =>
          curr is SessionDetailLoaded && curr.actionMessage != null,
      listener: (context, state) {
        final loaded = state as SessionDetailLoaded;
        if (loaded.actionIsError) {
          AppSnackbar.showError(context, loaded.actionMessage!);
        } else {
          AppSnackbar.showSuccess(context, loaded.actionMessage!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceDefault,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDefault,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: const BackButton(color: AppColors.textMain),
          title: Text('Session Details', style: AppTextStyles.heading1),
        ),
        body: BlocConsumer<SessionDetailBloc, SessionDetailState>(
          listenWhen: (prev, curr) =>
              curr is SessionDetailLoaded &&
              (prev is! SessionDetailLoaded ||
                  prev.joinStatus != curr.joinStatus),
          listener: (context, state) {
            if (state is! SessionDetailLoaded) return;
            if (state.joinStatus == JoinStatus.success &&
                state.joinUrl != null) {
              _launchCall(context, state.joinUrl!);
            } else if (state.joinStatus == JoinStatus.failure) {
              AppSnackbar.showError(
                context,
                state.joinError ??
                    'Could not start the call. Please try again.',
              );
            }
          },
          builder: (context, state) {
            if (state is SessionDetailLoading ||
                state is SessionDetailInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is SessionDetailError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context
                    .read<SessionDetailBloc>()
                    .add(SessionDetailStarted(sessionId: sessionId)),
              );
            }
            final loaded = state as SessionDetailLoaded;
            return _LoadedBody(
              session: loaded.session,
              child: loaded.child,
              joinStatus: loaded.joinStatus,
              isRescheduling: loaded.isRescheduling,
            );
          },
        ),
      ),
    );
  }
}

// ─── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.textSubtle),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTextStyles.body.copyWith(color: AppColors.textMain),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 160,
              child: AppPrimaryButton(label: 'Retry', onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loaded body ───────────────────────────────────────────────────────────────

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({
    required this.session,
    required this.child,
    required this.joinStatus,
    this.isRescheduling = false,
  });

  final SessionModel session;
  final ChildModel? child;
  final JoinStatus joinStatus;
  final bool isRescheduling;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Rebuild every 30 s so time-gated UI (join window, past-due card) stays
    // in sync without requiring the user to leave and re-enter.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final child = widget.child;
    final joinStatus = widget.joinStatus;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xl,
        AppSpacing.screenMargin,
        AppSpacing.xl5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(session: session, child: child),
          const SizedBox(height: AppSpacing.xl),
          if (session.status == 'upcoming' && !session.isPastDue) ...[
            _ModeActionCard(session: session, joinStatus: joinStatus),
            const SizedBox(height: AppSpacing.xl),
          ],
          _SectionLabel('Patient'),
          const SizedBox(height: AppSpacing.sm),
          _PatientCard(session: session, child: child),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel('Session Notes'),
          const SizedBox(height: AppSpacing.sm),
          _NotesCard(session: session),
          const SizedBox(height: AppSpacing.md),
          _PrivateNotesCard(session: session),
          // Actions only apply while the session is still upcoming.
          if (session.status == 'upcoming') ...[
            const SizedBox(height: AppSpacing.xl3),
            if (session.isPastDue) ...[
              const _NeedsReviewHint(),
              const SizedBox(height: AppSpacing.md),
              _MarkCompletedButton(session: session),
              const SizedBox(height: AppSpacing.sm),
            ],
            _SecondaryButton(
              label: 'Reschedule',
              color: AppColors.secondary,
              onPressed: () => _showRescheduleSheet(context, session),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SecondaryButton(
              label: 'Cancel',
              color: AppColors.error,
              onPressed: () async {
                final bloc = context.read<SessionDetailBloc>();
                final confirmed = await showModalBottomSheet<bool>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => CancelSessionSheet(session: session),
                );
                if (confirmed == true && context.mounted) {
                  bloc.add(SessionDetailCancelRequested(sessionId: session.id));
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Needs-review hint ───────────────────────────────────────────────────────

class _NeedsReviewHint extends StatelessWidget {
  const _NeedsReviewHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppColors.textDisabled),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "This session's time has passed. Mark it completed if it "
              'happened, or cancel it.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textDisabled, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mark as Completed ───────────────────────────────────────────────────────

class _MarkCompletedButton extends StatelessWidget {
  const _MarkCompletedButton({required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final bloc = context.read<SessionDetailBloc>();
          final confirmed = await showAppConfirmDialog(
            context: context,
            title: 'Mark as completed?',
            message:
                "This moves ${session.childName}'s session to your past sessions.",
            confirmLabel: 'Mark Completed',
            confirmColor: AppColors.primary,
          );
          if (confirmed) {
            bloc.add(SessionDetailMarkCompleted(sessionId: session.id));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          ),
        ),
        child: Text('Complete',
            style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.textWhite)),
      ),
    );
  }
}

// ─── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.session, required this.child});

  final SessionModel session;
  final ChildModel? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderInactive),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: session.childName, radius: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.childName,
                        style: AppTextStyles.subtitle
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (child != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(_patientSummary(child!),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textDisabled)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusPill(
                  status: session.isPastDue ? 'needs_review' : session.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(height: 1, color: AppColors.dividerLight),
          ),
          _DetailRow(label: 'Date', value: _formatDate(session.scheduledAt)),
          _DetailRow(label: 'Time', value: session.formattedTimeRange),
          _DetailRow(label: 'Duration', value: _formatDuration(session)),
          _DetailRow(label: 'Mode', value: session.mode),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textDisabled)),
          Text(value, style: AppTextStyles.body.copyWith(height: 1.0)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'completed' => ('Completed', AppColors.success20, AppColors.success),
      'cancelled' => ('Cancelled', AppColors.error20, AppColors.error),
      'needs_review' => ('Needs review', AppColors.inputFill, AppColors.textDisabled),
      _ => ('Upcoming', AppColors.secondary20, AppColors.secondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(label,
          style: AppTextStyles.tag
              .copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Mode action card ──────────────────────────────────────────────────────────

class _ModeActionCard extends StatelessWidget {
  const _ModeActionCard({required this.session, required this.joinStatus});

  final SessionModel session;
  final JoinStatus joinStatus;

  @override
  Widget build(BuildContext context) {
    final isVirtual = session.mode == 'Virtual';
    final icon =
        isVirtual ? Icons.videocam_outlined : Icons.location_on_outlined;
    final title = isVirtual ? 'Video Call' : session.location;

    // Virtual: gate the Join button on the time window; In-person: still stubbed.
    final isJoinable = isVirtual && session.isJoinable;
    final subtitle = isVirtual
        ? (isJoinable
            ? 'Link opens in your meeting app'
            : _virtualSubtitle(session))
        : 'In-person session';
    final buttonLabel = isVirtual ? 'Join Meeting' : 'Get Directions';

    void onButtonPressed() {
      if (isVirtual) {
        context.read<SessionDetailBloc>().add(const SessionJoinRequested());
      } else {
        AppSnackbar.showError(context, 'Directions are coming soon');
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary20,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.xs2),
                    Text(subtitle,
                        style: AppTextStyles.tag
                            .copyWith(color: AppColors.secondary80)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: buttonLabel,
            isLoading: joinStatus == JoinStatus.loading,
            // Virtual button disables outside the join window; in-person stays
            // tappable (stub). `null` renders the disabled grey state.
            onPressed: (isVirtual && !isJoinable) ? null : onButtonPressed,
          ),
        ],
      ),
    );
  }
}

/// Explains why a Virtual session can't be joined yet (button disabled).
String _virtualSubtitle(SessionModel session) {
  if (session.status == 'cancelled') return 'This session was cancelled';
  final now = DateTime.now();
  final lead = SessionModel.joinLeadTime;
  if (now.isBefore(session.scheduledAt.subtract(lead))) {
    return 'Join opens ${lead.inMinutes} min before the start time';
  }
  return 'This session has ended';
}

// ─── Patient card ──────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.session, required this.child});

  final SessionModel session;
  final ChildModel? child;

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      onTap: child == null
          ? () => AppSnackbar.showError(context, 'Could not load patient profile.')
          : () => context.push(
                Routes.patientDetails,
                extra: PatientDetailArgs(
                  patient: child!,
                  therapistId:
                      FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
              ),
      child: Row(
        children: [
          _Avatar(name: session.childName, radius: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.childName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600, height: 1.2)),
                if (child != null) ...[
                  const SizedBox(height: AppSpacing.xs2),
                  Text(_patientSummary(child!),
                      style: AppTextStyles.tag
                          .copyWith(color: AppColors.textDisabled)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.iconDefault),
        ],
      ),
    );
  }
}

// ─── Notes card ────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final hasNotes = session.notes != null && session.notes!.trim().isNotEmpty;
    return _TappableCard(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => hasNotes
                ? SessionNotesEditScreen(session: session)
                : SessionNotesFormScreen(session: session),
          ),
        );
        if (result == true && context.mounted) {
          context.read<SessionDetailBloc>().add(
                SessionDetailStarted(sessionId: session.id),
              );
        }
      },
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              hasNotes ? session.notes!.trim() : 'Add session notes',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                  height: 1.2,
                  color:
                      hasNotes ? AppColors.textMain : AppColors.textPlaceholder),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.iconDefault),
        ],
      ),
    );
  }
}

// ─── Private notes card (therapist-only) ──────────────────────────────────────

class _PrivateNotesCard extends StatelessWidget {
  const _PrivateNotesCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final hasNotes =
        session.privateNotes != null && session.privateNotes!.trim().isNotEmpty;

    return _TappableCard(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => hasNotes
                ? SessionNotesEditScreen(session: session)
                : SessionNotesFormScreen(session: session),
          ),
        );
        if (result == true && context.mounted) {
          context
              .read<SessionDetailBloc>()
              .add(SessionDetailStarted(sessionId: session.id));
        }
      },
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 20, color: AppColors.textSubtle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private Notes',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  hasNotes
                      ? session.privateNotes!.trim()
                      : 'Add private notes (not visible to parent)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                      height: 1.2,
                      color: hasNotes
                          ? AppColors.textMain
                          : AppColors.textPlaceholder),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.iconDefault),
        ],
      ),
    );
  }
}

// ─── Shared bits ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style:
            AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600));
  }
}

class _TappableCard extends StatelessWidget {
  const _TappableCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDefault,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.borderInactive),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondary20,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTextStyles.body
            .copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          ),
        ),
        child: Text(label,
            style: AppTextStyles.body
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Reschedule sheet ─────────────────────────────────────────────────────────

Future<void> _showRescheduleSheet(
    BuildContext context, SessionModel session) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RescheduleSheet(
      session: session,
      onConfirm: (newDate, newTime) async {
        final scheduledAt = DateTime(
          newDate.year, newDate.month, newDate.day,
          newTime.hour, newTime.minute,
        );
        final duration = session.endTime.difference(session.scheduledAt);
        final endTime = scheduledAt.add(duration);
        await SessionRepository().rescheduleSession(
        sessionId: session.id,
        newStart: scheduledAt,
        newEnd: endTime,
        mode: session.mode,
        location: session.location,
        durationMinutes: endTime.difference(scheduledAt).inMinutes,
      );
      },
    ),
  );
  if (result == true && context.mounted) {
    context
        .read<SessionDetailBloc>()
        .add(SessionDetailStarted(sessionId: session.id));
  }
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.session, required this.onConfirm});
  final SessionModel session;
  final Future<void> Function(DateTime date, TimeOfDay time) onConfirm;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current session values
    _selectedDate = widget.session.scheduledAt;
    _selectedTime = TimeOfDay.fromDateTime(widget.session.scheduledAt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final session = widget.session;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text('Reschedule Session',
              style: AppTextStyles.heading1.copyWith(color: AppColors.textMain)),
          const SizedBox(height: 16),
          // Session context card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  '${session.childName} · ${session.type}',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.textMain),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.formattedDateShort} · ${TimeOfDay.fromDateTime(session.scheduledAt).format(context)} · ${session.mode}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // New Date
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
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDefault,
                border: Border.all(color: AppColors.borderInactive),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Select date',
                    style: AppTextStyles.body.copyWith(color: AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // New Time
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
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDefault,
                border: Border.all(color: AppColors.borderInactive),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 18, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Text(
                    _selectedTime != null
                        ? _formatTime(_selectedTime!)
                        : 'Select time',
                    style: AppTextStyles.body.copyWith(color: AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Info text
          Text(
            'The parent will be notified of the change.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_loading || _selectedDate == null || _selectedTime == null)
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await widget.onConfirm(_selectedDate!, _selectedTime!);
                        if (mounted) {
                          Navigator.of(context).pop(true);
                          AppSnackbar.showSuccess(
                              context, 'Session rescheduled successfully.');
                        }
                      } catch (_) {
                        if (mounted) {
                          AppSnackbar.showError(
                              context, 'Could not reschedule. Please try again.');
                          setState(() => _loading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Reschedule & Notify Parent',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel
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

void _showCancelDialog(BuildContext context, SessionModel session) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cancel Session'),
      content: Text(
        'Are you sure you want to cancel the session with ${session.childName}?\n\nThe parent will be notified.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Keep Session'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            try {
              await SessionRepository().cancelSession(session.id);
              if (context.mounted) {
                context.read<SessionDetailBloc>()
                    .add(SessionDetailStarted(sessionId: session.id));
                AppSnackbar.showSuccess(context, 'Session cancelled.');
              }
            } catch (_) {
              if (context.mounted) {
                AppSnackbar.showError(
                    context, 'Could not cancel. Please try again.');
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancel Session'),
        ),
      ],
    ),
  );
}

// ─── Side effects ──────────────────────────────────────────────────────────────

/// Opens the JaaS call URL in the device's browser / meeting app. Surfaces a
/// friendly error if no app can handle it.
Future<void> _launchCall(BuildContext context, Uri url) async {
  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppSnackbar.showError(context, 'Could not open the call. Please try again.');
  }
}

// ─── Formatting helpers ────────────────────────────────────────────────────────

String _patientSummary(ChildModel child) {
  return 'ASD L${child.severityLevel} · ${_ageInYears(child.dateOfBirth)} yrs';
}

int _ageInYears(DateTime dob) {
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

String _formatDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

String _formatDuration(SessionModel session) {
  final mins = session.endTime.difference(session.scheduledAt).inMinutes;
  return '$mins min';
}
