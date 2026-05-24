import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../bloc/incident_form_cubit.dart';
import '../../bloc/incident_form_state.dart';
import '../../data/incident_repository.dart';
import '../widgets/incident_saved_dialog.dart';

// ── Chip options (from Figma frame 882:4124) ─────────────────────────────────

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

// ── Public entry point ────────────────────────────────────────────────────────

class IncidentFormArgs {
  final String patientId;
  final String patientName;
  final String? therapistName;

  const IncidentFormArgs({
    required this.patientId,
    required this.patientName,
    this.therapistName,
  });
}

class IncidentFormScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String? therapistName;

  const IncidentFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.therapistName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidentFormCubit(
        repository: IncidentRepository(),
        childId: patientId,
      ),
      child: _IncidentFormView(
        patientName: patientName,
        therapistName: therapistName,
      ),
    );
  }
}

// ── View — manages text controllers + status listener ────────────────────────

class _IncidentFormView extends StatefulWidget {
  final String patientName;
  final String? therapistName;

  const _IncidentFormView({required this.patientName, this.therapistName});

  @override
  State<_IncidentFormView> createState() => _IncidentFormViewState();
}

class _IncidentFormViewState extends State<_IncidentFormView> {
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
    _antecedentCtrl = TextEditingController();
    _behaviorCtrl = TextEditingController();
    _consequenceCtrl = TextEditingController();
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
        builder: (_) => IncidentSavedDialog(
          patientName: widget.patientName,
          time: state.time.format(context),
          therapistName: widget.therapistName,
          onBackToLogs: () {
            Navigator.of(context).pop();
            context.pop();
          },
          onLogAnother: () {
            Navigator.of(context).pop();
            context.read<IncidentFormCubit>().reset();
            _antecedentCtrl.clear();
            _behaviorCtrl.clear();
            _consequenceCtrl.clear();
          },
        ),
      );
    } else if (state.status == IncidentFormStatus.error) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Could not save', style: AppTextStyles.heading2),
          content: Text(
            state.errorMessage ?? 'Something went wrong. Please try again.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
      );
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
            body: Column(
              children: [
                _TopBar(patientName: widget.patientName),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenMargin,
                      AppSpacing.xl2,
                      AppSpacing.screenMargin,
                      AppSpacing.xl4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TabRow(),
                        const SizedBox(height: AppSpacing.lg),
                        _DateTimeRow(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _AntecedentCard(
                          key: _antecedentKey,
                          state: state,
                          controller: _antecedentCtrl,
                        ),
                        const SizedBox(height: AppSpacing.xl2),
                        _BehaviorCard(
                          key: _behaviorKey,
                          state: state,
                          patientName: widget.patientName,
                          controller: _behaviorCtrl,
                        ),
                        const SizedBox(height: AppSpacing.xl2),
                        _ConsequenceCard(
                          key: _consequenceKey,
                          state: state,
                          controller: _consequenceCtrl,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _VideoSection(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _SaveButton(state: state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String patientName;

  const _TopBar({required this.patientName});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEE d MMM yyyy').format(DateTime.now());
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin, 0,
          AppSpacing.screenMargin, AppSpacing.lg,
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
                    Icons.arrow_back_ios,
                    size: 18,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Log Incident', style: AppTextStyles.heading1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.secondaryOrange,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    'INCIDENT',
                    style: AppTextStyles.tag.copyWith(
                      color: AppColors.secondaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$patientName · $today',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab row ───────────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  const _TabRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceDefault,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: AppColors.textMain,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Manual',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // TODO(sprint-next): wire up Quick Log tab — placeholder only for now
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.flash_on_outlined,
                  size: 13,
                  color: AppColors.textPlaceholder,
                ),
                const SizedBox(width: 6),
                Text(
                  'Quick Log',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPlaceholder,
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

// ── Date / time row ───────────────────────────────────────────────────────────

class _DateTimeRow extends StatelessWidget {
  final IncidentFormState state;

  const _DateTimeRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncidentFormCubit>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Date'),
              const SizedBox(height: 6),
              _PickerField(
                icon: Icons.calendar_today_outlined,
                value: DateFormat('EEE d MMM yyyy').format(state.date),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && context.mounted) {
                    cubit.dateChanged(picked);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Time'),
              const SizedBox(height: 6),
              _PickerField(
                icon: Icons.access_time_outlined,
                value: state.time.format(context),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: state.time,
                  );
                  if (picked != null && context.mounted) {
                    cubit.timeChanged(picked);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section A: Antecedent ─────────────────────────────────────────────────────

class _AntecedentCard extends StatelessWidget {
  final IncidentFormState state;
  final TextEditingController controller;

  const _AntecedentCard({super.key, required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncidentFormCubit>();
    final showErr = state.showErrors;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'A', title: 'Antecedent'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'What led to this moment?',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            'Describe what happened',
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

// ── Section B: Behavior ───────────────────────────────────────────────────────

class _BehaviorCard extends StatelessWidget {
  final IncidentFormState state;
  final String patientName;
  final TextEditingController controller;

  const _BehaviorCard({
    super.key,
    required this.state,
    required this.patientName,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncidentFormCubit>();
    final showErr = state.showErrors;
    final firstName = patientName.split(' ').first;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'B', title: 'Behavior'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'What $firstName did',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            'Describe the behavior you observed',
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

// ── Section C: Consequence ────────────────────────────────────────────────────

class _ConsequenceCard extends StatelessWidget {
  final IncidentFormState state;
  final TextEditingController controller;

  const _ConsequenceCard({super.key, required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncidentFormCubit>();
    final showErr = state.showErrors;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'C', title: 'Consequence'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'How you responded',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            'Describe how you responded',
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
  final IncidentFormState state;

  const _VideoSection({required this.state});

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
    final isUploading = state.status == IncidentFormStatus.videoUploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTACH A VIDEO (OPTIONAL)',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.325,
            color: AppColors.textPlaceholder,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.videoThumbnailPath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: Image.file(
              File(state.videoThumbnailPath!),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (isUploading) ...[
          const LinearProgressIndicator(
            backgroundColor: AppColors.inputFill,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _VideoRow(
          icon: Icons.videocam_outlined,
          label: 'Take a video',
          onTap: isUploading ? null : () => _pick(context, ImageSource.camera),
        ),
        const SizedBox(height: AppSpacing.md),
        _VideoRow(
          icon: Icons.photo_library_outlined,
          label: 'Choose from gallery',
          onTap: isUploading ? null : () => _pick(context, ImageSource.gallery),
        ),
      ],
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final IncidentFormState state;

  const _SaveButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == IncidentFormStatus.saving;
    final isDisabled = state.status == IncidentFormStatus.videoUploading;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading || isDisabled
            ? null
            : () => context.read<IncidentFormCubit>().submit(),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.save_outlined,
                    size: 16,
                    color: AppColors.textWhite,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Save Incident',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Shared mini-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

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
  final String letter;
  final String title;

  const _SectionHeader({required this.letter, required this.title});

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
  final String text;
  final bool hasError;

  const _FieldLabel(this.text, {this.hasError = false});

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
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool hasError;

  const _TextAreaField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
    this.hasError = false,
  });

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
          color: const Color(0xFFB3B3B3),
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
  final String label;
  final List<String> chips;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final bool hasError;

  const _ChipGroup({
    required this.label,
    required this.chips,
    required this.selected,
    required this.onToggle,
    this.hasError = false,
  });

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
  final String label;
  final int? value;
  final bool hasError;
  final ValueChanged<int> onChanged;

  const _SeverityRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

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
  final bool? value;
  final bool hasError;
  final ValueChanged<bool> onChanged;

  const _DidItWorkToggle({
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

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
            borderRadius: BorderRadius.circular(50),
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
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 1.5,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.textWhite : AppColors.textPlaceholder,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  final IncidentFormState state;

  const _DurationField({required this.state});

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
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                  ),
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
    final showErr =
        state.showErrors && state.behaviorDuration == Duration.zero;
    final formatted = _formatDuration(state.behaviorDuration);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Duration', hasError: showErr),
        const SizedBox(height: 6),
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
                        ? const Color(0xFFB3B3B3)
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

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          border: Border.all(color: AppColors.borderInactive),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textPlaceholder),
            const SizedBox(width: AppSpacing.sm),
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _VideoRow({
    required this.icon,
    required this.label,
    this.onTap,
  });

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
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: onTap == null
                  ? AppColors.textDisabled
                  : AppColors.textMain,
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
              color: onTap == null
                  ? AppColors.textDisabled
                  : AppColors.textMain,
            ),
          ],
        ),
      ),
    );
  }
}
