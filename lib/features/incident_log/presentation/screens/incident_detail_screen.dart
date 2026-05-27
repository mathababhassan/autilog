import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/child_model.dart';
import '../../../../shared/models/incident_model.dart';
import '../../../../shared/models/therapist_feedback_model.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/locked_state_badge.dart';
import '../../../../shared/widgets/video_card.dart';
import '../../bloc/incident_detail_bloc.dart';
import '../../bloc/incident_detail_event.dart';
import '../../bloc/incident_detail_state.dart';
import '../../data/incident_repository.dart';

// ─── Args ─────────────────────────────────────────────────────

class IncidentDetailArgs {
  final String incidentId;
  final ChildModel child;

  const IncidentDetailArgs({
    required this.incidentId,
    required this.child,
  });
}

// ─── Screen (public entry) ────────────────────────────────────

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.args});

  final IncidentDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidentDetailBloc(repository: IncidentRepository()),
      child: _IncidentDetailView(args: args),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────

class _IncidentDetailView extends StatefulWidget {
  const _IncidentDetailView({required this.args});

  final IncidentDetailArgs args;

  @override
  State<_IncidentDetailView> createState() => _IncidentDetailViewState();
}

class _IncidentDetailViewState extends State<_IncidentDetailView> {
  @override
  void initState() {
    super.initState();
    context.read<IncidentDetailBloc>().add(IncidentDetailStarted(
      parentId: widget.args.child.parentId,
      childId: widget.args.child.childId,
      incidentId: widget.args.incidentId,
      child: widget.args.child,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IncidentDetailBloc, IncidentDetailState>(
      listenWhen: (prev, curr) {
        if (curr is! IncidentDetailLoaded) return false;
        if (prev is IncidentDetailLoaded &&
            prev.actionStatus == curr.actionStatus) return false;
        return curr.actionStatus != IncidentDetailActionStatus.idle &&
            curr.actionStatus != IncidentDetailActionStatus.deleting;
      },
      listener: (context, state) {
        if (state is! IncidentDetailLoaded) { return; }
        if (state.actionStatus == IncidentDetailActionStatus.deleteSuccess) {
          context.pop();
        } else if (state.actionStatus == IncidentDetailActionStatus.deleteError &&
            state.actionMessage != null) {
          AppSnackbar.showError(context, state.actionMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surfaceDefault,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(state: state),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, IncidentDetailState state) {
    if (state is IncidentDetailInitial || state is IncidentDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (state is IncidentDetailError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Text(
            state.message,
            style: AppTextStyles.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final loaded = state as IncidentDetailLoaded;
    return _LoadedBody(
      incident: loaded.incident,
      child: loaded.child,
      isDeleting: loaded.actionStatus == IncidentDetailActionStatus.deleting,
      isLocked: DateTime.now().difference(loaded.incident.createdAt) >= const Duration(hours: 24),
      onDelete: () => _showDeleteSheet(context),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (_) => _DeleteSheet(
        onConfirm: () {
          Navigator.pop(context);
          context.read<IncidentDetailBloc>().add(
                const IncidentDetailDeleteRequested(),
              );
        },
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final IncidentDetailState state;

  @override
  Widget build(BuildContext context) {
    final loaded = state is IncidentDetailLoaded ? state as IncidentDetailLoaded : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(
          bottom: BorderSide(color: AppColors.borderInactive),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Behavioral Incident',
                  style: AppTextStyles.heading1,
                ),
              ),
              if (loaded != null) const _IncidentTag(),
            ],
          ),
          if (loaded != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl2),
              child: Text(
                '${_formatIncidentDate(loaded.incident.date)} · ${loaded.child.name}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPlaceholder),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IncidentTag extends StatelessWidget {
  const _IncidentTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        'INCIDENT',
        style: AppTextStyles.tag.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Loaded Body ──────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.incident,
    required this.child,
    required this.isDeleting,
    required this.isLocked,
    required this.onDelete,
  });

  final IncidentModel incident;
  final ChildModel child;
  final bool isDeleting;
  final bool isLocked;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final firstName = child.name.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // A — Antecedent
          _SectionCard(
            letter: 'A',
            title: 'Antecedent',
            subtitle: 'What led to this moment',
            children: [
              Text(
                incident.antecedentDescription,
                style: AppTextStyles.body.copyWith(color: AppColors.textMain),
              ),
              const SizedBox(height: AppSpacing.md),
              if (incident.antecedentTriggers.isNotEmpty) ...[
                _LabeledField(
                  label: 'Trigger',
                  child: _ReadOnlyChips(labels: incident.antecedentTriggers),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _LabeledField(
                label: 'Severity',
                child: _SeverityRating(value: incident.antecedentSeverity),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // B — Behavior
          _SectionCard(
            letter: 'B',
            title: 'Behavior',
            subtitle: 'What $firstName did',
            children: [
              Text(
                incident.behaviorDescription,
                style: AppTextStyles.body.copyWith(color: AppColors.textMain),
              ),
              const SizedBox(height: AppSpacing.md),
              if (incident.behaviorTypes.isNotEmpty) ...[
                _LabeledField(
                  label: 'Behavior Type',
                  child: _ReadOnlyChips(labels: incident.behaviorTypes),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _LabeledField(
                label: 'Duration',
                child: Text(
                  _formatDuration(incident.behaviorDuration),
                  style: AppTextStyles.body.copyWith(color: AppColors.textMain),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Severity',
                child: _SeverityRating(value: incident.behaviorSeverity),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // C — Consequence
          _SectionCard(
            letter: 'C',
            title: 'Consequence',
            subtitle: 'How you responded',
            children: [
              Text(
                incident.consequenceDescription,
                style: AppTextStyles.body.copyWith(color: AppColors.textMain),
              ),
              const SizedBox(height: AppSpacing.md),
              if (incident.strategies.isNotEmpty) ...[
                _LabeledField(
                  label: 'Strategy',
                  child: _ReadOnlyChips(labels: incident.strategies),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _LabeledField(
                label: 'Did it work?',
                child: _DidItWorkRow(didItWork: incident.didItWork),
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Effectiveness',
                child: _SeverityRating(value: incident.effectiveness),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          if (incident.videoUrl != null) ...[
            VideoCard(videoUrl: incident.videoUrl!),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (child.linkedTherapistId != null) ...[
            _TherapistFeedbackCard(feedback: incident.therapistFeedback),
            const SizedBox(height: AppSpacing.lg),
          ],

          _LogFooter(updatedAt: incident.updatedAt),
          const SizedBox(height: AppSpacing.lg),
          if (isLocked) ...[
            const LockedStateBadge(),
            const SizedBox(height: AppSpacing.lg),
          ],

          _ActionButtons(
            isDeleting: isDeleting,
            isLocked: isLocked,
            onDelete: onDelete,
          ),

          const SizedBox(height: AppSpacing.xl2),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.letter,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String letter;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border.all(color: AppColors.borderInactive),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LetterBadge(letter: letter),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            // Indent past badge (28px) + gap (8px)
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              subtitle,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPlaceholder),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _ReadOnlyChips extends StatelessWidget {
  const _ReadOnlyChips({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: labels
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.tag.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SeverityRating extends StatelessWidget {
  const _SeverityRating({required this.value});

  final int value;

  static const _total = 5;

  String _label() {
    if (value <= 2) return 'LOW';
    if (value == 3) return 'MED';
    return 'HIGH';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(_total, (i) {
          final filled = i < value;
          return Container(
            margin: EdgeInsets.only(right: i < _total - 1 ? AppSpacing.sm : 0),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.primary : null,
              border: filled
                  ? null
                  : Border.all(color: AppColors.borderInactive, width: 1.2),
            ),
          );
        }),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$value/$_total',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _label(),
          style: AppTextStyles.tag.copyWith(
            color: AppColors.textDisabled,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DidItWorkRow extends StatelessWidget {
  const _DidItWorkRow({required this.didItWork});

  final bool didItWork;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: didItWork ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          didItWork ? 'Yes' : 'No',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Therapist Feedback Card ──────────────────────────────────

class _TherapistFeedbackCard extends StatelessWidget {
  const _TherapistFeedbackCard({required this.feedback});

  final TherapistFeedback? feedback;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.secondary20,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: feedback == null
          ? Text(
              'No feedback yet',
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(feedback!.therapistName),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        feedback!.therapistName,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '· ${_formatShortDate(feedback!.createdAt)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(
                  height: 1,
                  color: AppColors.secondary.withValues(alpha: 0.25),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  feedback!.comment,
                  style: AppTextStyles.body.copyWith(color: AppColors.textMain),
                ),
              ],
            ),
    );
  }
}

// ─── Log Footer ───────────────────────────────────────────────

class _LogFooter extends StatelessWidget {
  const _LogFooter({required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last edited: ${_formatLastEdited(updatedAt)}',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPlaceholder,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Logs lock 24 hours after saving.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPlaceholder),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isDeleting,
    required this.isLocked,
    required this.onDelete,
  });

  final bool isDeleting;
  final bool isLocked;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isDeleting ? null : onDelete,
          icon: isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textDisabled,
                  ),
                )
              : const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textDisabled,
            side: const BorderSide(color: AppColors.borderInactive),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
            textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDeleting
                ? null
                : () => AppSnackbar.showError(context, 'Edit is coming soon'),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
              textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDeleting ? null : onDelete,
            icon: isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textDisabled,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDisabled,
              side: const BorderSide(color: AppColors.borderInactive),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
              textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Delete Sheet ─────────────────────────────────────────────

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xl2,
        AppSpacing.screenMargin,
        AppSpacing.xl2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delete Incident Log?', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This action cannot be undone.',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textPlaceholder),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                    ),
                  ),
                  child: Text(
                    'Delete',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Date Helpers ─────────────────────────────────────────────

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatIncidentDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

String _formatShortDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';

String _formatLastEdited(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day} ${_months[d.month - 1]} ${d.year} at $h:$m $ampm';
}

String _formatDuration(Duration d) {
  if (d.inMinutes == 0) return '< 1 minute';
  if (d.inHours > 0) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return m > 0 ? '$h hr $m min' : '$h hr';
  }
  final m = d.inMinutes;
  return '$m ${m == 1 ? 'minute' : 'minutes'}';
}
