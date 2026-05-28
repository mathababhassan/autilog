import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/positive_moment_model.dart';
import '../../../../shared/models/therapist_feedback_model.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../bloc/positive_moment_detail_bloc.dart';
import '../../bloc/positive_moment_detail_event.dart';
import '../../bloc/positive_moment_detail_state.dart';
import '../../data/positive_moment_repository.dart';
import '../../positive_moment_route_args.dart';
import '../../../../core/constants/routes.dart';

// ─── Args ─────────────────────────────────────────────────────

class PositiveMomentDetailArgs {
  final String momentId;
  final String childId;
  final String childName;
  final String? parentId;

  const PositiveMomentDetailArgs({
    required this.momentId,
    required this.childId,
    required this.childName,
    this.parentId,
  });
}

// ─── Screen ───────────────────────────────────────────────────

class PositiveMomentDetailScreen extends StatelessWidget {
  const PositiveMomentDetailScreen({super.key, required this.args});

  final PositiveMomentDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PositiveMomentDetailBloc(
        repository: PositiveMomentRepository(),
      ),
      child: _PositiveMomentDetailView(args: args),
    );
  }
}

class _PositiveMomentDetailView extends StatefulWidget {
  const _PositiveMomentDetailView({required this.args});

  final PositiveMomentDetailArgs args;

  @override
  State<_PositiveMomentDetailView> createState() =>
      _PositiveMomentDetailViewState();
}

class _PositiveMomentDetailViewState extends State<_PositiveMomentDetailView> {
  @override
  void initState() {
    super.initState();
    final parentId =
        widget.args.parentId ?? FirebaseAuth.instance.currentUser?.uid;
    if (parentId == null) return;

    context.read<PositiveMomentDetailBloc>().add(
          PositiveMomentDetailStarted(
            parentId: parentId,
            childId: widget.args.childId,
            childName: widget.args.childName,
            momentId: widget.args.momentId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PositiveMomentDetailBloc, PositiveMomentDetailState>(
      listenWhen: (prev, curr) {
        if (curr is! PositiveMomentDetailLoaded) return false;
        if (prev is PositiveMomentDetailLoaded &&
            prev.actionStatus == curr.actionStatus) {
          return false;
        }
        return curr.actionStatus != PositiveMomentDetailActionStatus.idle &&
            curr.actionStatus != PositiveMomentDetailActionStatus.deleting;
      },
      listener: (context, state) {
        if (state is! PositiveMomentDetailLoaded) return;
        if (state.actionStatus ==
            PositiveMomentDetailActionStatus.deleteSuccess) {
          context.pop();
        } else if (state.actionStatus ==
                PositiveMomentDetailActionStatus.deleteError &&
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

  Widget _buildBody(BuildContext context, PositiveMomentDetailState state) {
    if (state is PositiveMomentDetailInitial ||
        state is PositiveMomentDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (state is PositiveMomentDetailError) {
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

    final loaded = state as PositiveMomentDetailLoaded;
    return _LoadedBody(
      moment: loaded.moment,
      childName: loaded.childName,
      showTherapistSection: loaded.linkedTherapistId != null,
      isDeleting:
          loaded.actionStatus == PositiveMomentDetailActionStatus.deleting,
      onDelete: () => _showDeleteSheet(context),
      onEdit: () => _onEdit(context, loaded),
    );
  }

  void _onEdit(BuildContext context, PositiveMomentDetailLoaded loaded) {
    if (loaded.moment.isLocked) {
      AppSnackbar.showError(
        context,
        'This log is locked. Logs cannot be edited after 24 hours.',
      );
      return;
    }
    context.push(
      Routes.positiveMomentForm,
      extra: PositiveMomentFormArgs(
        patientId: widget.args.childId,
        patientName: widget.args.childName,
        existingMoment: loaded.moment,
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    final loaded = context.read<PositiveMomentDetailBloc>().state;
    if (loaded is PositiveMomentDetailLoaded && loaded.moment.isLocked) {
      AppSnackbar.showError(
        context,
        'This log is locked. Logs cannot be deleted after 24 hours.',
      );
      return;
    }

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
          context.read<PositiveMomentDetailBloc>().add(
                const PositiveMomentDetailDeleteRequested(),
              );
        },
      ),
    );
  }
}

// ─── Top bar (P-27) ───────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final PositiveMomentDetailState state;

  @override
  Widget build(BuildContext context) {
    final loaded =
        state is PositiveMomentDetailLoaded ? state as PositiveMomentDetailLoaded : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.borderInactive)),
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
                  'Positive Moment',
                  style: AppTextStyles.heading1,
                ),
              ),
              if (loaded != null) const _PositiveMomentTag(),
            ],
          ),
          if (loaded != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl2),
              child: Text(
                '${_formatMomentDate(loaded.moment.date)} · ${loaded.childName}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PositiveMomentTag extends StatelessWidget {
  const _PositiveMomentTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        'POSITIVE MOMENT',
        style: AppTextStyles.tag.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Loaded body ──────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.moment,
    required this.childName,
    required this.showTherapistSection,
    required this.isDeleting,
    required this.onDelete,
    required this.onEdit,
  });

  final PositiveMomentModel moment;
  final String childName;
  final bool showTherapistSection;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final firstName = childName.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl2),

          _SectionCard(
            letter: 'A',
            title: 'Antecedent',
            subtitle: 'What set this moment up?',
            children: [
              Text(
                moment.antecedentDescription,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMain,
                  height: 1.6,
                ),
              ),
              if (moment.setting.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _LabeledField(
                  label: 'Setting',
                  child: _ReadOnlyChip(label: moment.setting),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _SectionCard(
            letter: 'B',
            title: 'Behavior',
            subtitle: 'What did $firstName do well?',
            children: [
              Text(
                moment.behaviorDescription,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMain,
                  height: 1.6,
                ),
              ),
              if (moment.behaviorTypes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _LabeledField(
                  label: 'Positive Behavior Type',
                  child: _ReadOnlyChips(labels: moment.behaviorTypes),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Positive Rating',
                child: _RatingRow(value: moment.positiveBehaviorRating),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _SectionCard(
            letter: 'C',
            title: 'Consequence',
            subtitle: 'How you responded',
            children: [
              Text(
                moment.consequenceDescription,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMain,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Effectiveness',
                child: _RatingRow(value: moment.effectiveness),
              ),
            ],
          ),

          if (moment.videoUrl != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _VideoCard(videoUrl: moment.videoUrl!),
          ],

          if (showTherapistSection) ...[
            const SizedBox(height: AppSpacing.lg),
            _TherapistFeedbackCard(feedback: moment.therapistFeedback),
          ],

          const SizedBox(height: AppSpacing.lg),
          _LogFooter(updatedAt: moment.updatedAt),
          const SizedBox(height: AppSpacing.lg),

          _ActionButtons(
            isDeleting: isDeleting,
            isLocked: moment.isLocked,
            onEdit: onEdit,
            onDelete: onDelete,
          ),

          const SizedBox(height: AppSpacing.xl2),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────

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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border.all(color: AppColors.borderInactive, width: 1.17),
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
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPlaceholder,
              ),
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
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPlaceholder,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  const _ReadOnlyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.tag.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
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
      children: labels.map((label) => _ReadOnlyChip(label: label)).toList(),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.value});

  final int value;

  static const _total = 5;

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
              color: filled ? AppColors.primary : AppColors.surfaceDefault,
              border: filled
                  ? null
                  : Border.all(color: AppColors.labelInactive, width: 1.17),
            ),
          );
        }),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$value/$_total',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPlaceholder,
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderInactive),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.videocam_outlined,
                size: 20,
                color: AppColors.textMain,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Attached Memory', style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () => AppSnackbar.showError(
              context,
              'Video playback is coming soon',
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                height: 180,
                color: AppColors.borderInactive,
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.textWhite,
                    size: 22,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.secondary20,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: feedback == null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'No feedback yet',
                style: AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
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
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPlaceholder,
                      ),
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
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMain,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
    );
  }
}

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
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: AppColors.iconDefault,
            ),
            const SizedBox(width: 6),
            Text(
              'Logs lock 24 hours after saving.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isDeleting,
    required this.isLocked,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isDeleting;
  final bool isLocked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDeleting || isLocked ? null : onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.textDisabled,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
              textStyle:
                  AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDeleting || isLocked ? null : onDelete,
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
              textStyle:
                  AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

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
          Text('Delete Positive Moment?', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This action cannot be undone.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPlaceholder,
            ),
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

// ─── Date helpers ─────────────────────────────────────────────

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatMomentDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

String _formatShortDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';

String _formatLastEdited(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day} ${_months[d.month - 1]} ${d.year} at $h:$m $ampm';
}
