import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../features/daily_log/bloc/daily_summary_bloc.dart';
import '../../../../../features/daily_log/data/daily_summary_repository.dart';
import '../../../../../shared/models/daily_summary_model.dart';
import '../widgets/sleep_details_sheet.dart';
import '../widgets/summary_saved_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class EditSummaryScreen extends StatelessWidget {
  final DailySummaryModel summary;

  const EditSummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DailySummaryBloc(repository: DailySummaryRepository()),
      child: _EditSummaryView(summary: summary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

class _EditSummaryView extends StatefulWidget {
  final DailySummaryModel summary;
  const _EditSummaryView({required this.summary});

  @override
  State<_EditSummaryView> createState() => _EditSummaryViewState();
}

class _EditSummaryViewState extends State<_EditSummaryView> {
  late Rating _sleepRating;
  late TimeOfDay? _bedtime;
  late TimeOfDay? _wakeTime;
  late Rating _moodRating;
  late bool _breakfastEaten;
  late bool _lunchEaten;
  late bool _dinnerEaten;
  late bool _routineNormal;
  late bool? _hadScreenTime;
  late bool? _tookMedication;
  final _screenTimeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.summary;
    _sleepRating = s.sleepRating;
    _bedtime = s.bedtime != null ? TimeOfDay.fromDateTime(s.bedtime!) : null;
    _wakeTime = s.wakeTime != null ? TimeOfDay.fromDateTime(s.wakeTime!) : null;
    _moodRating = s.moodRating;
    _breakfastEaten = s.breakfastEaten;
    _lunchEaten = s.lunchEaten;
    _dinnerEaten = s.dinnerEaten;
    _routineNormal = s.routineNormal;
    _hadScreenTime = s.hadScreenTime;
    _tookMedication = s.medicationTaken;
    _screenTimeController.text = s.screenTimeHours?.toString() ?? '';
    _notesController.text = s.notes ?? '';
  }

  @override
  void dispose() {
    _screenTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime? _toDateTime(TimeOfDay? time) {
    if (time == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  void _submit() {
    final updated = widget.summary.copyWith(
      sleepRating: _sleepRating,
      bedtime: _toDateTime(_bedtime),
      wakeTime: _toDateTime(_wakeTime),
      moodRating: _moodRating,
      breakfastEaten: _breakfastEaten,
      lunchEaten: _lunchEaten,
      dinnerEaten: _dinnerEaten,
      routineNormal: _routineNormal,
      hadScreenTime: _hadScreenTime,
      screenTimeHours: _hadScreenTime == true
          ? double.tryParse(_screenTimeController.text)
          : null,
      medicationTaken: _tookMedication ?? false,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    context.read<DailySummaryBloc>().add(UpdateDailySummaryEvent(updated));
  }

  void _showSleepDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SleepDetailsSheet(
        initialBedtime: _bedtime,
        initialWakeTime: _wakeTime,
        onSave: (bed, wake) {
          setState(() {
            _bedtime = bed;
            _wakeTime = wake;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, d MMMM yyyy').format(widget.summary.date);

    return BlocConsumer<DailySummaryBloc, DailySummaryState>(
      listener: (context, state) {
        if (state is DailySummaryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state is DailySummaryUpdated) {
          showDialog(
            context: context,
            barrierDismissible: false,
           builder: (_) => SummarySavedDialog(
  childId: widget.summary.childId,
),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state is DailySummarySaving;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            title: const Text('Edit Summary'),
            backgroundColor: const Color(0xFFFF8A00),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.summary.childId} · $formattedDate',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // ── Section 1: Sleep ────────────────────────────────────────
                const _SectionTitle('Section 1: Sleep'),
                const SizedBox(height: 16),
                _RatingRow(
                  selected: _sleepRating,
                  onSelected: (r) => setState(() => _sleepRating = r),
                ),
                const SizedBox(height: 8),
                _AddDetailsButton(onTap: _showSleepDetails),
                if (_bedtime != null || _wakeTime != null) ...[
                  const SizedBox(height: 8),
                  _SleepDetailChips(
                    bedtime: _toDateTime(_bedtime),
                    wakeTime: _toDateTime(_wakeTime),
                  ),
                ],
                const SizedBox(height: 28),

                // ── Section 2: Morning Mood ─────────────────────────────────
                const _SectionTitle('Section 2: Morning Mood'),
                const SizedBox(height: 16),
                _RatingRow(
                  selected: _moodRating,
                  onSelected: (r) => setState(() => _moodRating = r),
                ),
                const SizedBox(height: 28),

                // ── Section 3: Meals ────────────────────────────────────────
                const _SectionTitle('Section 3: Meals'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MealCard(
                        label: 'Breakfast',
                        eaten: _breakfastEaten,
                        onToggle: (v) => setState(() => _breakfastEaten = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MealCard(
                        label: 'Lunch',
                        eaten: _lunchEaten,
                        onToggle: (v) => setState(() => _lunchEaten = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MealCard(
                        label: 'Dinner',
                        eaten: _dinnerEaten,
                        onToggle: (v) => setState(() => _dinnerEaten = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Section 4: Routine ──────────────────────────────────────
                const _SectionTitle('Section 4: Routine'),
                const SizedBox(height: 8),
                const Text(
                  "Was today's routine normal?",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                _YesNoRow(
                  value: _routineNormal,
                  onChanged: (v) => setState(() => _routineNormal = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'What was different?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFFF8A00), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Added by Therapist ──────────────────────────────────────
                const _SectionTitle('Added by Therapist'),
                const SizedBox(height: 8),
                const Text(
                  'Did the child have screen time 1 hour before bed?',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                _YesNoRow(
                  value: _hadScreenTime,
                  onChanged: (v) => setState(() => _hadScreenTime = v),
                ),
                if (_hadScreenTime == true) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'For how many hours (optional)?',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  _ScreenTimeInputRow(controller: _screenTimeController),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Did the child take medication today?',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                _YesNoRow(
                  value: _tookMedication,
                  onChanged: (v) => setState(() => _tookMedication = v),
                ),
                const SizedBox(height: 32),

                // ── Save button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A7A6E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF1A7A6E).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 28),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            onTap: (i) {
              if (i == 0) context.go(Routes.parentHome);
            },
            selectedItemColor: const Color(0xFFFF8A00),
            unselectedItemColor: Colors.black38,
            type: BottomNavigationBarType.fixed,
            elevation: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Logs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Sessions',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen-time input row
// ─────────────────────────────────────────────────────────────────────────────

class _ScreenTimeInputRow extends StatelessWidget {
  final TextEditingController controller;
  const _ScreenTimeInputRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 1.5 hours',
              hintStyle:
                  const TextStyle(color: Colors.black38, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFFF8A00), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IntrinsicWidth(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => FocusScope.of(context).unfocus(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A7A6E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 0,
              ),
              child: const Text('Ok'),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating row
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final Rating? selected;
  final ValueChanged<Rating> onSelected;

  const _RatingRow({this.selected, required this.onSelected});

  static const _labels = ['Bad', 'Poor', 'Average', 'Good', 'Excellent'];
  static const _emojis = ['😡', '😟', '😐', '🙂', '😄'];
  static const _colors = [
    Color(0xFFD84C4C),
    Color(0xFFD84C4C),
    Color(0xFFE8A020),
    Color(0xFF5CA85C),
    Color(0xFF3B9E75),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(Rating.values.length, (i) {
        final rating = Rating.values[i];
        final isSelected = selected == rating;
        return GestureDetector(
          onTap: () => onSelected(rating),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? _colors[i].withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected ? _colors[i] : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _emojis[i],
                    style: TextStyle(fontSize: isSelected ? 26 : 22),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? _colors[i] : Colors.black38,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleep detail chips
// ─────────────────────────────────────────────────────────────────────────────

class _SleepDetailChips extends StatelessWidget {
  final DateTime? bedtime;
  final DateTime? wakeTime;

  const _SleepDetailChips({this.bedtime, this.wakeTime});

  String _fmt(DateTime dt) => DateFormat('h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (bedtime != null)
          Chip(
            label: Text('Bedtime: ${_fmt(bedtime!)}'),
            backgroundColor: const Color(0xFFFFF3E0),
            labelStyle: const TextStyle(
                fontSize: 12, color: Color(0xFFFF8A00)),
            side: const BorderSide(color: Color(0xFFFF8A00)),
          ),
        if (wakeTime != null)
          Chip(
            label: Text('Wake: ${_fmt(wakeTime!)}'),
            backgroundColor: const Color(0xFFFFF3E0),
            labelStyle: const TextStyle(
                fontSize: 12, color: Color(0xFFFF8A00)),
            side: const BorderSide(color: Color(0xFFFF8A00)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Details button
// ─────────────────────────────────────────────────────────────────────────────

class _AddDetailsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddDetailsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '+ Add Details',
            style: TextStyle(
              color: Color(0xFFFF8A00),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal card
// ─────────────────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final String label;
  final bool eaten;
  final ValueChanged<bool> onToggle;

  const _MealCard({
    required this.label,
    required this.eaten,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!eaten),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: eaten
              ? const Color(0xFFFF8A00).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: eaten
                ? const Color(0xFFFF8A00)
                : const Color(0xFFE0E0E0),
            width: eaten ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: eaten
                    ? const Color(0xFFFF8A00)
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              eaten ? 'Eaten' : 'Skipped',
              style: TextStyle(
                fontSize: 11,
                color: eaten ? const Color(0xFFFF8A00) : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yes / No row
// ─────────────────────────────────────────────────────────────────────────────

class _YesNoRow extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool> onChanged;

  const _YesNoRow({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _YesNoChip(
          label: 'Yes',
          selected: value == true,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 12),
        _YesNoChip(
          label: 'No',
          selected: value == false,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _YesNoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YesNoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF8A00).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF8A00)
                : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFFFF8A00)
                : const Color(0xFF1A1A1A),
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}