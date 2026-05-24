import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/child_model.dart';
import '../../../../shared/models/incident_model.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../bloc/incident_form_cubit.dart';
import '../../bloc/incident_form_state.dart';
import '../../data/incident_repository.dart';
import '../widgets/incident_updated_dialog.dart';

// ── Chip options ──────────────────────────────────────────────────────────────

const _triggers = [
  'Routine Change', 'Loud Environment', 'Hunger', 'Fatigue',
  'Crowded Place', 'Sensory Stimulus', 'Transition',
  'Social Demand', 'School Related', 'Unknown', 'Other',
];

const _behaviorTypes = [
  'Meltdown', 'Aggression', 'Self-harm', 'Repetitive Behavior',
  'Withdrawal', 'Refusal', 'Other',
];

const _strategies = [
  'Redirection', 'Reward', 'Ignore', 'Comfort',
  'Verbal Reassurance', 'Sensory Tool', 'Physical Comfort',
  'Quiet Space', 'Other',
];

// ── Helper ────────────────────────────────────────────────────────────────────

String _formatDuration(Duration d) {
  if (d == Duration.zero) return '';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

// ── Args + Screen ─────────────────────────────────────────────────────────────

class IncidentEditArgs {
  const IncidentEditArgs({
    required this.incident,
    required this.child,
  });

  final IncidentModel incident;
  final ChildModel child;
}

class IncidentEditScreen extends StatelessWidget {
  const IncidentEditScreen({super.key, required this.args});

  final IncidentEditArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidentFormCubit.fromIncident(
        incident: args.incident,
        repository: IncidentRepository(),
        childId: args.child.childId,
      ),
      child: _EditView(args: args),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _EditView extends StatefulWidget {
  const _EditView({required this.args});

  final IncidentEditArgs args;

  @override
  State<_EditView> createState() => _EditViewState();
}

class _EditViewState extends State<_EditView> {
  late final TextEditingController _antecedentCtrl;
  late final TextEditingController _behaviorCtrl;
  late final TextEditingController _consequenceCtrl;
  late final ScrollController _scrollController;

  final _antecedentKey = GlobalKey();
  final _behaviorKey = GlobalKey();
  final _consequenceKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final inc = widget.args.incident;
    _antecedentCtrl = TextEditingController(text: inc.antecedentDescription);
    _behaviorCtrl = TextEditingController(text: inc.behaviorDescription);
    _consequenceCtrl = TextEditingController(text: inc.consequenceDescription);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _antecedentCtrl.dispose();
    _behaviorCtrl.dispose();
    _consequenceCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFirstError(IncidentFormState state) {
    GlobalKey targetKey;
    if (state.antecedentDescription.trim().isEmpty ||
        state.antecedentTriggers.isEmpty ||
        state.antecedentSeverity == null) {
      targetKey = _antecedentKey;
    } else if (state.behaviorDescription.trim().isEmpty ||
        state.behaviorTypes.isEmpty ||
        state.behaviorDuration == Duration.zero ||
        state.behaviorSeverity == null) {
      targetKey = _behaviorKey;
    } else {
      targetKey = _consequenceKey;
    }
    final ctx = targetKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _onStateChanged(BuildContext context, IncidentFormState state) {
    if (state.showErrors && state.status == IncidentFormStatus.idle) {
      _scrollToFirstError(state);
      AppSnackbar.showError(context, 'Please fill in all required fields.');
      return;
    }
    if (state.status == IncidentFormStatus.success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => IncidentUpdatedDialog(
          patientName: widget.args.child.name,
          time: state.time.format(context),
          onBackToIncident: () {
            Navigator.of(context).pop();
            context.pop();
          },
        ),
      );
    } else if (state.status == IncidentFormStatus.error) {
      AppSnackbar.showError(
        context,
        state.errorMessage ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final video = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null && context.mounted) {
      context.read<IncidentFormCubit>().videoSelected(video);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncidentFormCubit, IncidentFormState>(
      listenWhen: (p, c) => p.status != c.status || (!p.showErrors && c.showErrors),
      listener: _onStateChanged,
      child: BlocBuilder<IncidentFormCubit, IncidentFormState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.surfaceDefault,
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    childName: widget.args.child.name,
                    incident: widget.args.incident,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenMargin,
                        AppSpacing.xl2,
                        AppSpacing.screenMargin,
                        AppSpacing.xl2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _InfoBanner(),
                          const SizedBox(height: AppSpacing.md),
                          const _IncidentTypeChip(),
                          const SizedBox(height: AppSpacing.md),
                          _ReadOnlyDateTimeRow(incident: widget.args.incident),
                          const SizedBox(height: AppSpacing.lg),
                          _AntecedentCard(
                            key: _antecedentKey,
                            state: state,
                            controller: _antecedentCtrl,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _BehaviorCard(
                            key: _behaviorKey,
                            state: state,
                            childName: widget.args.child.name,
                            controller: _behaviorCtrl,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _ConsequenceCard(
                            key: _consequenceKey,
                            state: state,
                            controller: _consequenceCtrl,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _VideoSection(
                            state: state,
                            onPick: (source) => _pick(context, source),
                            onRemove: () =>
                                context.read<IncidentFormCubit>().videoRemoved(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _SaveBar(state: state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.childName, required this.incident});

  final String childName;
  final IncidentModel incident;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE d MMM yyyy').format(incident.date);
    final time = incident.time.format(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.borderInactive)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('Edit Incident', style: AppTextStyles.heading1),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl2),
            child: Text(
              '$childName · $date · $time',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary20,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'You can edit this incident for 24 hours after saving.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Incident type chip ────────────────────────────────────────────────────────

class _IncidentTypeChip extends StatelessWidget {
  const _IncidentTypeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondaryOrange, width: 1.2),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        'BEHAVIORAL INCIDENT',
        style: AppTextStyles.tag.copyWith(
          color: AppColors.secondaryOrange,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Read-only date/time row ───────────────────────────────────────────────────

class _ReadOnlyDateTimeRow extends StatelessWidget {
  const _ReadOnlyDateTimeRow({required this.incident});

  final IncidentModel incident;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE d MMM yyyy').format(incident.date);
    final time = incident.time.format(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ReadOnlyPickerField(
            icon: Icons.calendar_today_outlined,
            value: date,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: _ReadOnlyPickerField(
            icon: Icons.access_time_outlined,
            value: time,
          ),
        ),
      ],
    );
  }
}

// ── A – Antecedent ────────────────────────────────────────────────────────────

class _AntecedentCard extends StatelessWidget {
  const _AntecedentCard({
    super.key,
    required this.state,
    required this.controller,
  });

  final IncidentFormState state;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncidentFormCubit>();
    final showErr = state.showErrors;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'A', title: 'Antecedent'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'What led to this moment',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            'Description',
            hasError: showErr && state.antecedentDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.xs),
          _TextAreaField(
            controller: controller,
            placeholder: 'Describe what happened before...',
            onChanged: cubit.antecedentDescriptionChanged,
            hasError: showErr && state.antecedentDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _ChipGroup(
            label: 'Trigger',
            chips: _triggers,
            selected: state.antecedentTriggers,
            onToggle: cubit.antecedentTriggerToggled,
            hasError: showErr && state.antecedentTriggers.isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _SeverityRow(
            label: 'Severity',
            value: state.antecedentSeverity,
            hasError: showErr && (state.antecedentSeverity ?? 0) == 0,
            onChanged: cubit.antecedentSeverityChanged,
          ),
        ],
      ),
    );
  }
}

// ── B – Behavior ──────────────────────────────────────────────────────────────

class _BehaviorCard extends StatelessWidget {
  const _BehaviorCard({
    super.key,
    required this.state,
    required this.childName,
    required this.controller,
  });

  final IncidentFormState state;
  final String childName;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncidentFormCubit>();
    final showErr = state.showErrors;
    final firstName = childName.split(' ').first;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'B', title: 'Behavior'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'What $firstName did',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            'Description',
            hasError: showErr && state.behaviorDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.xs),
          _TextAreaField(
            controller: controller,
            placeholder: 'Describe the behavior...',
            onChanged: cubit.behaviorDescriptionChanged,
            hasError: showErr && state.behaviorDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _ChipGroup(
            label: 'Behavior Type',
            chips: _behaviorTypes,
            selected: state.behaviorTypes,
            onToggle: cubit.behaviorTypeToggled,
            hasError: showErr && state.behaviorTypes.isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _DurationField(state: state),
          const SizedBox(height: AppSpacing.md),
          _SeverityRow(
            label: 'Severity',
            value: state.behaviorSeverity,
            hasError: showErr && (state.behaviorSeverity ?? 0) == 0,
            onChanged: cubit.behaviorSeverityChanged,
          ),
        ],
      ),
    );
  }
}

// ── C – Consequence ───────────────────────────────────────────────────────────

class _ConsequenceCard extends StatelessWidget {
  const _ConsequenceCard({
    super.key,
    required this.state,
    required this.controller,
  });

  final IncidentFormState state;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncidentFormCubit>();
    final showErr = state.showErrors;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'C', title: 'Consequence'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'How you responded',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            'Description',
            hasError: showErr && state.consequenceDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.xs),
          _TextAreaField(
            controller: controller,
            placeholder: 'How did you handle it?',
            onChanged: cubit.consequenceDescriptionChanged,
            hasError: showErr && state.consequenceDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _ChipGroup(
            label: 'Strategy',
            chips: _strategies,
            selected: state.strategies,
            onToggle: cubit.strategyToggled,
            hasError: showErr && state.strategies.isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _DidItWorkToggle(
            value: state.didItWork,
            hasError: showErr && state.didItWork == null,
            onChanged: cubit.didItWorkChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _SeverityRow(
            label: 'Effectiveness',
            value: state.effectiveness,
            hasError: showErr && (state.effectiveness ?? 0) == 0,
            onChanged: cubit.effectivenessChanged,
          ),
        ],
      ),
    );
  }
}

// ── Video section ─────────────────────────────────────────────────────────────

class _VideoSection extends StatelessWidget {
  const _VideoSection({
    required this.state,
    required this.onPick,
    required this.onRemove,
  });

  final IncidentFormState state;
  final void Function(ImageSource) onPick;
  final VoidCallback onRemove;

  void _showReplacePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.xl2,
          AppSpacing.screenMargin,
          AppSpacing.xl2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Replace Video', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.lg),
            _VideoRow(
              icon: Icons.videocam_outlined,
              label: 'Take a new video',
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _VideoRow(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = state.status == IncidentFormStatus.videoUploading;
    final hasVideo = state.videoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VIDEO (OPTIONAL)',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.325,
            color: AppColors.textPlaceholder,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isUploading) ...[
          const LinearProgressIndicator(
            backgroundColor: AppColors.inputFill,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (hasVideo) ...[
          if (state.videoThumbnailPath != null && !kIsWeb)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: Image.file(
                File(state.videoThumbnailPath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.textWhite,
                    size: 22,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: isUploading ? null : onRemove,
                child: Text(
                  'Remove video',
                  style: AppTextStyles.caption.copyWith(
                    color: isUploading
                        ? AppColors.textDisabled
                        : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl2),
              TextButton(
                onPressed: isUploading
                    ? null
                    : () => _showReplacePicker(context),
                child: Text(
                  'Replace video',
                  style: AppTextStyles.caption.copyWith(
                    color: isUploading
                        ? AppColors.textDisabled
                        : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ] else if (!isUploading) ...[
          _VideoRow(
            icon: Icons.videocam_outlined,
            label: 'Take a video',
            onTap: () => onPick(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.md),
          _VideoRow(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => onPick(ImageSource.gallery),
          ),
        ],
      ],
    );
  }
}

// ── Save bar ──────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.state});

  final IncidentFormState state;

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == IncidentFormStatus.saving;
    final isDisabled = state.status == IncidentFormStatus.videoUploading;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(top: BorderSide(color: AppColors.borderInactive)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading || isDisabled
              ? null
              : () => context.read<IncidentFormCubit>().update(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.inputFill,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.textWhite,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save Changes',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Shared mini-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.letter, required this.title});

  final String letter;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
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
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.subtitle),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.hasError = false});

  final String text;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: hasError ? AppColors.error : AppColors.textPlaceholder,
      ),
    );
  }
}

class _TextAreaField extends StatelessWidget {
  const _TextAreaField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 6,
      onChanged: onChanged,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPlaceholder,
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        filled: true,
        fillColor: AppColors.surfaceDefault,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.borderInactive,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.chips,
    required this.selected,
    required this.onToggle,
    this.hasError = false,
  });

  final String label;
  final List<String> chips;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, hasError: hasError),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: chips.map((chip) {
            final isSelected = selected.contains(chip);
            return GestureDetector(
              onTap: () => onToggle(chip),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceDefault,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderInactive,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Text(
                  chip.toUpperCase(),
                  style: AppTextStyles.tag.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textDisabled,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SeverityRow extends StatelessWidget {
  const _SeverityRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final String label;
  final int? value;
  final ValueChanged<int> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, hasError: hasError),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            ...List.generate(5, (i) {
              final filled = value != null && i < value!;
              return GestureDetector(
                onTap: () => onChanged(value == i + 1 ? 0 : i + 1),
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : AppColors.surfaceDefault,
                    border: Border.all(
                      color: filled
                          ? AppColors.primary
                          : hasError && value == null
                              ? AppColors.error
                              : AppColors.borderInactive,
                    ),
                  ),
                ),
              );
            }),
            Text(
              value == null ? '–/5' : '$value/5',
              style: AppTextStyles.caption.copyWith(
                color: hasError && value == null
                    ? AppColors.error
                    : AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DidItWorkToggle extends StatelessWidget {
  const _DidItWorkToggle({
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final bool? value;
  final ValueChanged<bool> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Did it work?', hasError: hasError),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 36,
          width: 120,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          ),
          child: Row(
            children: [
              _ToggleBtn(
                label: 'Yes',
                isActive: value == true,
                activeColor: AppColors.success,
                onTap: () => onChanged(true),
              ),
              _ToggleBtn(
                label: 'No',
                isActive: value == false,
                activeColor: AppColors.error,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.textWhite : AppColors.textPlaceholder,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({required this.state});

  final IncidentFormState state;

  Future<void> _showPicker(BuildContext context) async {
    Duration result = state.behaviorDuration;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => Container(
        height: 280,
        color: AppColors.surfaceDefault,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: Text(
                  'Done',
                  style: AppTextStyles.body.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: state.behaviorDuration,
                onTimerDurationChanged: (d) => result = d,
              ),
            ),
          ],
        ),
      ),
    );
    if (context.mounted) {
      context.read<IncidentFormCubit>().behaviorDurationChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showErr = state.showErrors && state.behaviorDuration == Duration.zero;
    final formatted = _formatDuration(state.behaviorDuration);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Duration', hasError: showErr),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              border: Border.all(
                color: showErr ? AppColors.error : AppColors.borderInactive,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatted.isEmpty ? 'How long did it last?' : formatted,
                  style: AppTextStyles.body.copyWith(
                    color: formatted.isEmpty
                        ? AppColors.textPlaceholder
                        : AppColors.textMain,
                  ),
                ),
                Text(
                  'hh:mm',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 57,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          border: Border.all(color: AppColors.borderInactive),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: onTap == null ? AppColors.textDisabled : AppColors.textMain,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: onTap == null
                      ? AppColors.textDisabled
                      : AppColors.textMain,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: onTap == null ? AppColors.textDisabled : AppColors.textMain,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyPickerField extends StatelessWidget {
  const _ReadOnlyPickerField({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textPlaceholder),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.body.copyWith(color: AppColors.textMain),
          ),
        ],
      ),
    );
  }
}
