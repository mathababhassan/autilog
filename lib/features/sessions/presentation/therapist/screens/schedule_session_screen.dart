import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/child_model.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../../patients/data/patient_repository.dart';
import '../../../bloc/schedule_session_bloc.dart';
import '../../../data/session_repository.dart';

// ─── Screen (provides BLoC) ──────────────────────────────────────────────────

class ScheduleSessionScreen extends StatelessWidget {
  const ScheduleSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduleSessionBloc(
        sessionRepository: SessionRepository(),
        patientRepository: context.read<PatientRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..add(ScheduleSessionStarted()),
      child: const _ScheduleSessionView(),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────

class _ScheduleSessionView extends StatelessWidget {
  const _ScheduleSessionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textMain),
        title: Text('Schedule Session', style: AppTextStyles.display),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.borderInactive),
        ),
      ),
      body: BlocConsumer<ScheduleSessionBloc, ScheduleSessionState>(
        listenWhen: (prev, curr) {
          if (curr is ScheduleSessionSuccess) return true;
          if (curr is ScheduleSessionReady && curr.serverError != null) {
            if (prev is ScheduleSessionReady) {
              return prev.serverError != curr.serverError;
            }
            return true;
          }
          return false;
        },
        listener: (context, state) {
          if (state is ScheduleSessionSuccess) {
            _showSuccessDialog(context);
          } else if (state is ScheduleSessionReady && state.serverError != null) {
            AppSnackbar.showError(context, state.serverError!);
          }
        },
        buildWhen: (_, curr) => curr is! ScheduleSessionSuccess,
        builder: (context, state) {
          return switch (state) {
            ScheduleSessionInitial() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ScheduleSessionLoadError(:final message) => _ErrorBody(message: message),
            ScheduleSessionReady() => _FormBody(state: state),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

void _showSuccessDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _SuccessDialog(
      onClose: () {
        Navigator.of(dialogContext).pop();
        context.go(Routes.therapistSessions);
      },
    ),
  );
}

// ─── Form body ────────────────────────────────────────────────────────────────

class _FormBody extends StatefulWidget {
  const _FormBody({required this.state});

  final ScheduleSessionReady state;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  late final TextEditingController _parentNotesCtrl;
  late final TextEditingController _privateNotesCtrl;

  @override
  void initState() {
    super.initState();
    _parentNotesCtrl = TextEditingController(text: widget.state.parentNotes);
    _privateNotesCtrl = TextEditingController(text: widget.state.privateNotes);
  }

  @override
  void dispose() {
    _parentNotesCtrl.dispose();
    _privateNotesCtrl.dispose();
    super.dispose();
  }

  ScheduleSessionBloc get _bloc => context.read<ScheduleSessionBloc>();

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xl2,
        AppSpacing.screenMargin,
        AppSpacing.xl5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Patient ───────────────────────────────────────────────────
          const _FieldLabel(label: 'Patient'),
          const SizedBox(height: AppSpacing.xs),
          _PatientSelector(
            selected: s.selectedPatient,
            patients: s.patients,
            error: s.fieldErrors['patient'],
            onSelected: (p) => _bloc.add(ScheduleSessionPatientSelected(p)),
          ),

          const SizedBox(height: AppSpacing.xl3),
          const _SectionDivider(label: 'SESSION DETAILS'),
          const SizedBox(height: AppSpacing.xl3),

          // ── Session Type ──────────────────────────────────────────────
          const _FieldLabel(label: 'Session Type'),
          const SizedBox(height: AppSpacing.sm),
          _ChipGroup(
            options: const [
              'Assessment',
              'Behavioral Intervention',
              'Follow-up',
              'Parent Consultation',
            ],
            selected: s.selectedType,
            onSelect: (t) => _bloc.add(ScheduleSessionTypeSelected(t)),
          ),
          if (s.fieldErrors['type'] != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _ErrorText(s.fieldErrors['type']!),
          ],

          const SizedBox(height: AppSpacing.xl3),

          // ── Location ──────────────────────────────────────────────────
          const _FieldLabel(label: 'Location'),
          const SizedBox(height: AppSpacing.sm),
          _LocationToggle(
            selected: s.selectedMode,
            onSelect: (m) => _bloc.add(ScheduleSessionModeSelected(m)),
          ),

          const SizedBox(height: AppSpacing.xl3),
          const _SectionDivider(label: 'SCHEDULING'),
          const SizedBox(height: AppSpacing.xl3),

          // ── Date ──────────────────────────────────────────────────────
          const _FieldLabel(label: 'Date', required: true),
          const SizedBox(height: AppSpacing.xs),
          _DateField(
            date: s.selectedDate,
            error: s.fieldErrors['date'],
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: s.selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null && context.mounted) {
                _bloc.add(ScheduleSessionDateSelected(picked));
              }
            },
          ),

          const SizedBox(height: AppSpacing.xl3),

          // ── Time ──────────────────────────────────────────────────────
          const _FieldLabel(label: 'Time', required: true),
          const SizedBox(height: AppSpacing.xs),
          _TimeField(
            time: s.selectedTime,
            error: s.fieldErrors['time'],
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: s.selectedTime ?? TimeOfDay.now(),
              );
              if (picked != null && context.mounted) {
                _bloc.add(ScheduleSessionTimeSelected(picked));
              }
            },
          ),

          const SizedBox(height: AppSpacing.xl3),

          // ── Duration ──────────────────────────────────────────────────
          const _FieldLabel(label: 'Duration', required: true),
          const SizedBox(height: AppSpacing.sm),
          _DurationChips(
            selected: s.selectedDurationMinutes,
            error: s.fieldErrors['duration'],
            onPresetSelected: (m) => _bloc.add(ScheduleSessionDurationSelected(m)),
            onCustomTap: () => _showDurationPicker(context, s.selectedDurationMinutes),
          ),

          const SizedBox(height: AppSpacing.xl3),
          const _SectionDivider(label: 'NOTES'),
          const SizedBox(height: AppSpacing.xl3),

          // ── Notes for Parent ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel(label: 'Notes for Parent'),
              Text(
                '(Optional)',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPlaceholder),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _NotesArea(
            controller: _parentNotesCtrl,
            placeholder: 'Add any instructions or context for the parent...',
            onChanged: (v) => _bloc.add(ScheduleSessionParentNotesChanged(v)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sent to parent with the session confirmation.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),

          const SizedBox(height: AppSpacing.xl3),

          // ── Private Notes ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel(label: 'Private Notes'),
              Text(
                '(Optional · Therapist only)',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPlaceholder),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _NotesArea(
            controller: _privateNotesCtrl,
            placeholder: 'Personal prep notes, goals for this session...',
            onChanged: (v) =>
                _bloc.add(ScheduleSessionPrivateNotesChanged(v)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Not shared with the parent. Visible only to you.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),

          const SizedBox(height: AppSpacing.xl4),

          // ── Submit ────────────────────────────────────────────────────
          AppPrimaryButton(
            label: 'Schedule & Notify Parent',
            isLoading: s.isSubmitting,
            onPressed: s.isSubmitting
                ? null
                : () => _bloc.add(ScheduleSessionSubmitted()),
          ),
        ],
      ),
    );
  }

  void _showDurationPicker(BuildContext context, int? current) {
    const step = 5;
    const min = 5;
    const max = 180;
    final options = [for (var i = min; i <= max; i += step) i];

    final defaultIndex = options.indexWhere((m) => m == 60).clamp(0, options.length - 1);
    final initialIndex = current != null
        ? options.indexWhere((m) => m == current).let((i) => i < 0 ? defaultIndex : i)
        : defaultIndex;

    var picked = options[initialIndex];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (sheetCtx) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textPlaceholder),
                      ),
                    ),
                    Text('Duration', style: AppTextStyles.subtitle),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _bloc.add(ScheduleSessionDurationSelected(picked));
                      },
                      child: Text(
                        'Done',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerLight),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  itemExtent: 44,
                  onSelectedItemChanged: (i) => picked = options[i],
                  children: options
                      .map((m) => Center(
                            child: Text(
                              '$m min',
                              style: AppTextStyles.body.copyWith(fontSize: 17),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Section divider ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 1, color: AppColors.dividerLight),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),
        ),
        const Expanded(
          child: Divider(thickness: 1, color: AppColors.dividerLight),
        ),
      ],
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    if (!required) {
      return Text(label, style: AppTextStyles.subtitle);
    }
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: AppTextStyles.subtitle,
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// ─── Error text ───────────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTextStyles.caption.copyWith(color: AppColors.error),
    );
  }
}

// ─── Patient selector ─────────────────────────────────────────────────────────

class _PatientSelector extends StatelessWidget {
  const _PatientSelector({
    required this.selected,
    required this.patients,
    required this.onSelected,
    this.error,
  });

  final ChildModel? selected;
  final List<ChildModel> patients;
  final String? error;
  final ValueChanged<ChildModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.secondary,
              ),
            ),
            child: Row(
              children: [
                if (selected != null) ...[
                  _InitialsAvatar(name: selected!.name, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      selected!.name,
                      style: AppTextStyles.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Select patient',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textPlaceholder),
                    ),
                  ),
                SvgPicture.asset(
                  'assets/icons/ic_chevron_down.svg',
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPlaceholder,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (hasError)
          _ErrorText(error!)
        else
          Text(
            'Tap to select a patient.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    if (patients.isEmpty) {
      AppSnackbar.showError(
        context,
        'No patients linked to your account yet.',
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (sheetCtx) => _PatientPickerSheet(
        patients: patients,
        selected: selected,
        onSelected: (p) {
          Navigator.pop(sheetCtx);
          onSelected(p);
        },
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary40,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}

class _PatientPickerSheet extends StatelessWidget {
  const _PatientPickerSheet({
    required this.patients,
    required this.selected,
    required this.onSelected,
  });

  final List<ChildModel> patients;
  final ChildModel? selected;
  final ValueChanged<ChildModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.xl,
            AppSpacing.screenMargin,
            AppSpacing.sm,
          ),
          child: Text('Select Patient', style: AppTextStyles.heading2),
        ),
        const Divider(height: 1, color: AppColors.dividerLight),
        ...patients.map(
          (p) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
              vertical: AppSpacing.xs,
            ),
            leading: _InitialsAvatar(name: p.name, size: 36),
            title: Text(p.name, style: AppTextStyles.body),
            trailing: selected?.childId == p.childId
                ? const Icon(Icons.check, color: AppColors.secondary)
                : null,
            onTap: () => onSelected(p),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
      ],
    );
  }
}

// ─── Chip group ───────────────────────────────────────────────────────────────

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.surfaceDefault,
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              border: Border.all(
                color: isSelected ? AppColors.secondary : AppColors.borderInactive,
              ),
            ),
            child: Text(
              o,
              style: AppTextStyles.body.copyWith(
                color: isSelected ? AppColors.textWhite : AppColors.textMain,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Location toggle ──────────────────────────────────────────────────────────

class _LocationToggle extends StatelessWidget {
  const _LocationToggle({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  static const _options = ['In-Person', 'Virtual'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Row(
        children: _options.map((o) {
          final isSelected = o == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surfaceDefault
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.pillRadius),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected
                        ? AppColors.textMain
                        : AppColors.textPlaceholder,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Date field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap, this.error});

  final DateTime? date;
  final VoidCallback onTap;
  final String? error;

  String _format(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              borderRadius:
                  BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.borderInactive,
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_calendar.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    date != null
                        ? AppColors.textMain
                        : AppColors.textPlaceholder,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  date != null ? _format(date!) : 'Select date',
                  style: AppTextStyles.body.copyWith(
                    color: date != null
                        ? AppColors.textMain
                        : AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          _ErrorText(error!),
        ],
      ],
    );
  }
}

// ─── Time field ───────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  const _TimeField({required this.time, required this.onTap, this.error});

  final TimeOfDay? time;
  final VoidCallback onTap;
  final String? error;

  String _format(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              borderRadius:
                  BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.borderInactive,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: time != null
                      ? AppColors.textMain
                      : AppColors.textPlaceholder,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  time != null ? _format(time!) : 'Select time',
                  style: AppTextStyles.body.copyWith(
                    color: time != null
                        ? AppColors.textMain
                        : AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          _ErrorText(error!),
        ],
      ],
    );
  }
}

// ─── Duration chips ───────────────────────────────────────────────────────────

class _DurationChips extends StatelessWidget {
  const _DurationChips({
    required this.selected,
    required this.onPresetSelected,
    required this.onCustomTap,
    this.error,
  });

  final int? selected;
  final ValueChanged<int> onPresetSelected;
  final VoidCallback onCustomTap;
  final String? error;

  static const _presets = [30, 45, 60];

  bool get _isCustom =>
      selected != null && !_presets.contains(selected);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ..._presets.map(
              (m) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _DurationChip(
                  label: '$m min',
                  isSelected: selected == m,
                  onTap: () => onPresetSelected(m),
                ),
              ),
            ),
            _DurationChip(
              label: _isCustom ? '$selected min' : 'Custom',
              isSelected: _isCustom,
              onTap: onCustomTap,
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _ErrorText(error!),
        ],
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.borderInactive,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isSelected ? AppColors.textWhite : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}

// ─── Notes text area ──────────────────────────────────────────────────────────

class _NotesArea extends StatelessWidget {
  const _NotesArea({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      minLines: 4,
      onChanged: onChanged,
      style: AppTextStyles.caption,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: AppTextStyles.caption
            .copyWith(color: AppColors.textPlaceholder),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        filled: true,
        fillColor: AppColors.surfaceDefault,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.borderInactive),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ─── Success dialog ───────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.secondary20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Session Scheduled successfully',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The session has been scheduled and the parent has been notified.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textPlaceholder),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: onClose,
                child: Text(
                  'Close',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textPlaceholder),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Extension ────────────────────────────────────────────────────────────────

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
