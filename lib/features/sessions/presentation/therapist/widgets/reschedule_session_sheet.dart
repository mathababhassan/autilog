import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/session_model.dart';

// ─── Public return type ───────────────────────────────────────────────────────

class RescheduleResult {
  const RescheduleResult({
    required this.newStart,
    required this.newEnd,
    required this.mode,
    required this.location,
    required this.durationMinutes,
  });

  final DateTime newStart;
  final DateTime newEnd;
  final String mode;
  final String location;
  final int durationMinutes;
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class RescheduleSessionSheet extends StatefulWidget {
  const RescheduleSessionSheet({super.key, required this.session});

  final SessionModel session;

  @override
  State<RescheduleSessionSheet> createState() =>
      _RescheduleSessionSheetState();
}

class _RescheduleSessionSheetState extends State<RescheduleSessionSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  late int _durationMinutes;
  late String _mode;

  static const _presets = [30, 45, 60];

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _date = s.scheduledAt;
    _time = TimeOfDay.fromDateTime(s.scheduledAt);
    _durationMinutes = s.durationMinutes;
    _mode = s.mode;
  }

  String _locationFor(String mode) => mode == 'Virtual' ? 'Online' : 'Clinic';

  String _formatDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _sessionSummaryLine() {
    final d = widget.session.scheduledAt;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final t = TimeOfDay.fromDateTime(d);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month]}'
        ' · $hour:$minute $period · ${widget.session.mode}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _showDurationPicker() {
    const step = 5;
    const minVal = 5;
    const maxVal = 180;
    final options = [for (var i = minVal; i <= maxVal; i += step) i];

    final fallback =
        options.indexWhere((m) => m == 60).clamp(0, options.length - 1);
    final idx = options.indexWhere((m) => m == _durationMinutes);
    final initialIndex = idx < 0 ? fallback : idx;

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
                        setState(() => _durationMinutes = picked);
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
                  scrollController:
                      FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 44,
                  onSelectedItemChanged: (i) => picked = options[i],
                  children: options
                      .map(
                        (m) => Center(
                          child: Text(
                            '$m min',
                            style: AppTextStyles.body.copyWith(fontSize: 17),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirm() {
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    Navigator.of(context).pop(
      RescheduleResult(
        newStart: start,
        newEnd: start.add(Duration(minutes: _durationMinutes)),
        mode: _mode,
        location: _locationFor(_mode),
        durationMinutes: _durationMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomDuration = !_presets.contains(_durationMinutes);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          Text('Reschedule Session', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.lg),

          // Session summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.session.childName} · ${widget.session.type}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  _sessionSummaryLine(),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textDisabled),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // New Date
          _FieldLabel('New Date'),
          const SizedBox(height: AppSpacing.xs),
          _FieldButton(
            icon: SvgPicture.asset(
              'assets/icons/ic_calendar.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                  AppColors.textMain, BlendMode.srcIn),
            ),
            value: _formatDate(_date),
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.md),

          // New Time
          _FieldLabel('New Time'),
          const SizedBox(height: AppSpacing.xs),
          _FieldButton(
            icon: const Icon(Icons.access_time,
                size: 18, color: AppColors.textMain),
            value: _formatTime(_time),
            onTap: _pickTime,
          ),
          const SizedBox(height: AppSpacing.md),

          // Duration
          _FieldLabel('Duration'),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              ..._presets.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _Chip(
                    label: '$m min',
                    isSelected: _durationMinutes == m,
                    onTap: () => setState(() => _durationMinutes = m),
                  ),
                ),
              ),
              _Chip(
                label: isCustomDuration ? '$_durationMinutes min' : 'Custom',
                isSelected: isCustomDuration,
                onTap: _showDurationPicker,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Mode
          _FieldLabel('Mode'),
          const SizedBox(height: AppSpacing.xs),
          _ModeToggle(
            selected: _mode,
            onSelect: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Notice
          Text(
            'The parent will be notified of the change.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // CTA — teal filled pill (DS §10 action-confirmation variant)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Reschedule & Notify Parent',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Cancel
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textMain),
      ),
    );
  }
}

// ─── Tap-to-open field button ─────────────────────────────────────────────────

class _FieldButton extends StatelessWidget {
  const _FieldButton({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final Widget icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderInactive),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.md),
            Text(
              value,
              style: AppTextStyles.body.copyWith(color: AppColors.textMain),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Duration / selection chip ────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
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
          color:
              isSelected ? AppColors.secondary : AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : AppColors.borderInactive,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color:
                isSelected ? AppColors.textWhite : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}

// ─── In-Person / Virtual toggle ───────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.selected, required this.onSelect});

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
