import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../bloc/positive_moment_form_cubit.dart';
import '../../bloc/positive_moment_form_state.dart';
import '../../data/positive_moment_repository.dart';
import '../../positive_moment_route_args.dart';
import 'positive_moment_detail_screen.dart';
import '../widgets/log_form_app_bar.dart';
import '../widgets/positive_moment_saved_dialog.dart';

const _settings = [
  'Home',
  'School',
  'Public Place',
  'Social Visit',
  'Therapy Session',
  'Other',
];

const _behaviorTypes = [
  'Social Interaction',
  'Communication',
  'Self-Regulation',
  'Cooperation',
  'New Skill',
  'Other',
];

class PositiveMomentFormScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PositiveMomentFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PositiveMomentFormCubit(
        repository: PositiveMomentRepository(),
        childId: patientId,
      ),
      child: _PositiveMomentFormView(
        patientId: patientId,
        patientName: patientName,
      ),
    );
  }
}

class _PositiveMomentFormView extends StatefulWidget {
  final String patientId;
  final String patientName;

  const _PositiveMomentFormView({
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_PositiveMomentFormView> createState() => _PositiveMomentFormViewState();
}

class _PositiveMomentFormViewState extends State<_PositiveMomentFormView> {
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

  void _scrollToFirstError(PositiveMomentFormState state) {
    GlobalKey targetKey;
    if (state.antecedentDescription.trim().isEmpty ||
        state.setting == null ||
        state.setting!.isEmpty) {
      targetKey = _antecedentKey;
    } else if (state.behaviorDescription.trim().isEmpty ||
        state.behaviorTypes.isEmpty ||
        (state.positiveBehaviorRating ?? 0) == 0) {
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

  void _onStateChanged(BuildContext context, PositiveMomentFormState state) {
    if (state.showErrors &&
        state.status == PositiveMomentFormStatus.idle) {
      _scrollToFirstError(state);
      AppSnackbar.showError(context, 'Please fill in all required fields.');
      return;
    }
    if (state.status == PositiveMomentFormStatus.success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PositiveMomentSavedDialog(
          patientName: widget.patientName,
          time: state.time.format(context),
          onBackToHome: () {
            Navigator.of(context).pop();
            context.go(Routes.parentHome);
          },
          onViewDetail: state.savedMomentId != null
              ? () {
                  final momentId = state.savedMomentId!;
                  Navigator.of(context).pop();
                  context.pushReplacement(
                    Routes.positiveMomentDetail,
                    extra: PositiveMomentDetailArgs(
                      momentId: momentId,
                      childId: widget.patientId,
                      childName: widget.patientName,
                    ),
                  );
                }
              : null,
          onLogAnother: () {
            Navigator.of(context).pop();
            context.read<PositiveMomentFormCubit>().reset();
            _antecedentCtrl.clear();
            _behaviorCtrl.clear();
            _consequenceCtrl.clear();
          },
        ),
      );
    } else if (state.status == PositiveMomentFormStatus.error) {
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
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return BlocListener<PositiveMomentFormCubit, PositiveMomentFormState>(
      listenWhen: (p, c) =>
          p.status != c.status || (!p.showErrors && c.showErrors),
      listener: _onStateChanged,
      child: BlocBuilder<PositiveMomentFormCubit, PositiveMomentFormState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.surfaceDefault,
            body: Column(
              children: [
                _Header(
                  patientName: widget.patientName,
                  dateLabel: dateStr,
                ),
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
                        _TimeField(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _AntecedentCard(
                          key: _antecedentKey,
                          state: state,
                          patientName: widget.patientName,
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
                        _MemorySection(state: state),
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

// ── Orange header (P19) ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String patientName;
  final String dateLabel;

  const _Header({required this.patientName, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -24,
                top: 8,
                child: _DecorCircle(size: 120, opacity: 0.18),
              ),
              Positioned(
                right: 40,
                top: 56,
                child: _DecorCircle(size: 72, opacity: 0.12),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LogFormAppBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenMargin,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.go(Routes.parentHome),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_ios,
                                size: 14,
                                color: AppColors.textWhite,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Back to Home',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Log A Positive Moment',
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          patientName,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textWhite.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textWhite.withValues(alpha: opacity),
      ),
    );
  }
}

// ── Manual / Quick Log tabs ───────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  const _TabRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: Text(
              'Manual',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: Text(
              'Quick Log',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Time of moment ────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  final PositiveMomentFormState state;

  const _TimeField({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PositiveMomentFormCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time of Moment',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: state.time,
            );
            if (picked != null && context.mounted) {
              cubit.timeChanged(picked);
            }
          },
          child: Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              border: Border.all(color: AppColors.borderInactive),
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              state.time.format(context),
              style: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }
}

// ── ABC sections ──────────────────────────────────────────────────────────────

class _AntecedentCard extends StatelessWidget {
  final PositiveMomentFormState state;
  final String patientName;
  final TextEditingController controller;

  const _AntecedentCard({
    super.key,
    required this.state,
    required this.patientName,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PositiveMomentFormCubit>();
    final showErr = state.showErrors;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'A', title: 'Antecedent'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'What set this moment up? Describe the setting',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TextAreaField(
            controller: controller,
            placeholder:
                'Cousin visited, calm home environment....',
            onChanged: cubit.antecedentDescriptionChanged,
            hasError: showErr && state.antecedentDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingChips(
            selected: state.setting,
            hasError: showErr &&
                (state.setting == null || state.setting!.isEmpty),
            onSelected: cubit.settingChanged,
          ),
        ],
      ),
    );
  }
}

class _BehaviorCard extends StatelessWidget {
  final PositiveMomentFormState state;
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
    final cubit = context.read<PositiveMomentFormCubit>();
    final showErr = state.showErrors;
    final firstName = patientName.split(' ').first;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'B', title: 'Behavior'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'What did $firstName do well?',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TextAreaField(
            controller: controller,
            placeholder:
                'e.g. Played with his cousin, shared toys without prompting...',
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
          _RatingRow(
            label: 'Positive Behavior Rating',
            value: state.positiveBehaviorRating,
            hasError: showErr && (state.positiveBehaviorRating ?? 0) == 0,
            onChanged: cubit.positiveBehaviorRatingChanged,
          ),
        ],
      ),
    );
  }
}

class _ConsequenceCard extends StatelessWidget {
  final PositiveMomentFormState state;
  final TextEditingController controller;

  const _ConsequenceCard({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PositiveMomentFormCubit>();
    final showErr = state.showErrors;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(letter: 'C', title: 'Consequence'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'How did you respond?',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TextAreaField(
            controller: controller,
            placeholder:
                'e.g Praised him and gave him a sticker as a reward',
            onChanged: cubit.consequenceDescriptionChanged,
            hasError: showErr && state.consequenceDescription.trim().isEmpty,
          ),
          const SizedBox(height: AppSpacing.md),
          _RatingRow(
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

// ── Memory attachment ─────────────────────────────────────────────────────────

class _MemorySection extends StatelessWidget {
  final PositiveMomentFormState state;

  const _MemorySection({required this.state});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final video = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null && context.mounted) {
      context.read<PositiveMomentFormCubit>().videoSelected(video);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading =
        state.status == PositiveMomentFormStatus.videoUploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADD A MEMORY (OPTIONAL)',
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
        _MemoryRow(
          icon: Icons.videocam_outlined,
          label: 'Take a video',
          onTap: isUploading ? null : () => _pick(context, ImageSource.camera),
        ),
        const SizedBox(height: AppSpacing.md),
        _MemoryRow(
          icon: Icons.photo_library_outlined,
          label: 'Choose from gallery',
          onTap: isUploading ? null : () => _pick(context, ImageSource.gallery),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final PositiveMomentFormState state;

  const _SaveButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == PositiveMomentFormStatus.saving;
    final isDisabled =
        state.status == PositiveMomentFormStatus.videoUploading;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading || isDisabled
            ? null
            : () => context.read<PositiveMomentFormCubit>().submit(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
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
                    Icons.event_note_outlined,
                    size: 18,
                    color: AppColors.textWhite,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Save Positive Moment',
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

// ── Shared widgets ────────────────────────────────────────────────────────────

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
        Text(
          letter,
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '– $title',
          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
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

class _SettingChips extends StatelessWidget {
  final String? selected;
  final bool hasError;
  final ValueChanged<String> onSelected;

  const _SettingChips({
    required this.selected,
    required this.hasError,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setting',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: hasError ? AppColors.error : AppColors.textMain,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _settings.map((chip) {
            final isSelected = selected == chip;
            return GestureDetector(
              onTap: () => onSelected(chip),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
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
                  chip,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textMain,
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
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: hasError ? AppColors.error : AppColors.textMain,
          ),
        ),
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
                  horizontal: 14,
                  vertical: 8,
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
                  chip,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textMain,
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

class _RatingRow extends StatelessWidget {
  final String label;
  final int? value;
  final bool hasError;
  final ValueChanged<int> onChanged;

  const _RatingRow({
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
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: hasError ? AppColors.error : AppColors.textMain,
          ),
        ),
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
                    color: filled
                        ? AppColors.primary
                        : AppColors.surfaceDefault,
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

class _MemoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MemoryRow({
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
