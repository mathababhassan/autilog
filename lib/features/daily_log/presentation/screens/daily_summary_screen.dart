import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../features/daily_log/bloc/daily_summary_bloc.dart';
import '../../../../../features/daily_log/data/daily_summary_repository.dart';
import '../../../../../shared/models/daily_summary_model.dart';
import '../widgets/sleep_details_sheet.dart';
import '../widgets/summary_saved_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class DailySummaryScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final String parentId;

  const DailySummaryScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DailySummaryBloc(
        repository: DailySummaryRepository(),
      ),
      child: _DailySummaryView(
        childId: childId,
        childName: childName,
        parentId: parentId,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

class _DailySummaryView extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const _DailySummaryView({
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<_DailySummaryView> createState() => _DailySummaryViewState();
}

class _DailySummaryViewState extends State<_DailySummaryView> {
  Rating? _sleepRating;
  TimeOfDay? _bedtime;
  TimeOfDay? _wakeTime;
  Rating? _moodRating;
  bool _breakfastEaten = false;
  bool _lunchEaten = false;
  bool _dinnerEaten = false;
  bool _routineNormal = true;
  bool? _hadScreenTime;
  final _screenTimeController = TextEditingController();
  bool? _tookMedication;
  final _notesController = TextEditingController();

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? widget.parentId;

    final summary = DailySummaryModel(
      childId: widget.childId,
      date: DateTime.now(),
      sleepRating: _sleepRating ?? Rating.average,
      bedtime: _toDateTime(_bedtime),
      wakeTime: _toDateTime(_wakeTime),
      moodRating: _moodRating ?? Rating.average,
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
      createdBy: uid,
    );

    context.read<DailySummaryBloc>().add(SaveDailySummaryEvent(summary));
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
        onSave: (bedtime, wakeTime) {
          setState(() {
            _bedtime = bedtime;
            _wakeTime = wakeTime;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM').format(today);
    final topPadding = MediaQuery.of(context).padding.top;

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
        if (state is DailySummarySaved) {
          showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => SummarySavedDialog(childId: widget.childId),
);

        }
      },
      builder: (context, state) {
        final isSaving = state is DailySummarySaving;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _BannerDelegate(
                  topPadding: topPadding,
                  childName: widget.childName,
                  date: formattedDate,
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.parentHome),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section 1: Sleep ──────────────────────────────────
                      const _SectionTitle('Section 1: Sleep'),
                      const SizedBox(height: 8),
                      Text(
                        'How well did ${widget.childName} sleep last night?',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      _RatingRow(
                        selected: _sleepRating,
                        onSelected: (r) =>
                            setState(() => _sleepRating = r),
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

                      // ── Section 2: Morning Mood ───────────────────────────
                      const _SectionTitle('Section 2: Morning Mood'),
                      const SizedBox(height: 8),
                      Text(
                        "How was ${widget.childName}'s mood this morning?",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      _RatingRow(
                        selected: _moodRating,
                        onSelected: (r) =>
                            setState(() => _moodRating = r),
                      ),
                      const SizedBox(height: 28),

                      // ── Section 3: Meals ──────────────────────────────────
                      const _SectionTitle('Section 3: Meals'),
                      const SizedBox(height: 16),

                      // FIX: Expanded is placed HERE in the Row,
                      // not inside _MealCard itself.
                      Row(
                        children: [
                          Expanded(
                            child: _MealCard(
                              label: 'Breakfast',
                              eaten: _breakfastEaten,
                              onToggle: (v) =>
                                  setState(() => _breakfastEaten = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MealCard(
                              label: 'Lunch',
                              eaten: _lunchEaten,
                              onToggle: (v) =>
                                  setState(() => _lunchEaten = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MealCard(
                              label: 'Dinner',
                              eaten: _dinnerEaten,
                              onToggle: (v) =>
                                  setState(() => _dinnerEaten = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _AddDetailsButton(onTap: () {}),
                      const SizedBox(height: 28),

                      // ── Section 4: Routine ────────────────────────────────
                      const _SectionTitle('Section 4: Routine'),
                      const SizedBox(height: 8),
                      const Text(
                        "Was today's routine normal?",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      _YesNoRow(
                        value: _routineNormal,
                        onChanged: (v) =>
                            setState(() => _routineNormal = v),
                      ),
                      const SizedBox(height: 28),

                      // ── Therapist questions ───────────────────────────────
                      const _SectionTitle('Added by Dr. Sara'),
                      const SizedBox(height: 16),
                      Text(
                        'Did ${widget.childName} have screen time 1 hour before bed?',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      _YesNoRow(
                        value: _hadScreenTime,
                        onChanged: (v) =>
                            setState(() => _hadScreenTime = v),
                      ),

                      // FIX: Screen-time hours input row — ElevatedButton
                      // now has an explicit width via intrinsicWidth so it
                      // never receives an unbounded or zero constraint inside
                      // the Row alongside an Expanded TextField.
                      if (_hadScreenTime == true) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'For how many hours (optional)?',
                          style: TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        _ScreenTimeInputRow(
                            controller: _screenTimeController),
                      ],

                      const SizedBox(height: 20),
                      Text(
                        'Did ${widget.childName} take medication today?',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      _YesNoRow(
                        value: _tookMedication,
                        onChanged: (v) =>
                            setState(() => _tookMedication = v),
                      ),
                      const SizedBox(height: 28),

                      // ── Save button ───────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A7A6E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF1A7A6E)
                                    .withOpacity(0.6),
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
                                  'Save Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        height:
                            MediaQuery.of(context).padding.bottom + 28,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
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
                label: 'Log',
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
// Screen-time input row (extracted widget)
//
// FIX: Previously the ElevatedButton sat inside a SizedBox with height only —
// no width — next to an Expanded TextField. Flutter gave the button 0 or
// negative available width, leaving its RenderBox in NEEDS-LAYOUT state and
// triggering the hit-test crash.
//
// Solution: wrap the button in IntrinsicWidth so the Row can measure it
// before allocating remaining space to the Expanded TextField.
// ─────────────────────────────────────────────────────────────────────────────

class _ScreenTimeInputRow extends StatelessWidget {
  final TextEditingController controller;

  const _ScreenTimeInputRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // TextField takes all remaining space after the button is measured.
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,1}'),
              ),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 1.5 hours',
              hintStyle: const TextStyle(
                color: Colors.black38,
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF8A00),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // FIX: IntrinsicWidth lets the Row measure the button's natural
        // width first, so Expanded can correctly allocate the remainder.
        // The old code used SizedBox(height: 48) with no width, leaving
        // the button's render box permanently un-laid-out.
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
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
// Collapsing banner
// ─────────────────────────────────────────────────────────────────────────────

class _BannerDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final String childName;
  final String date;
  final VoidCallback onBack;

  const _BannerDelegate({
    required this.topPadding,
    required this.childName,
    required this.date,
    required this.onBack,
  });

  static const double _expandedHeight = 200;
  static const double _maxRadius = 32.0;

  @override
  double get maxExtent => _expandedHeight + topPadding;

  @override
  double get minExtent => kToolbarHeight + topPadding;

  @override
  bool shouldRebuild(_BannerDelegate old) =>
      old.topPadding != topPadding ||
      old.childName != childName ||
      old.date != date;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final radius = _maxRadius * (1 - progress);
    final subtitleOpacity = (1 - progress / 0.4).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: Container(
        color: const Color(0xFFFF8A00),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative circles — clipped by the Stack so no overflow
            Positioned(
              right: -20,
              top: 0,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              right: 110,
              top: 10,
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),

            // Expanded subtitle (fades out as header collapses)
            if (subtitleOpacity > 0)
              Positioned(
                left: 24,
                right: 130,
                top: topPadding + kToolbarHeight + 4,
                child: Opacity(
                  opacity: subtitleOpacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        childName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Toolbar row (always visible)
            Positioned(
              left: 0,
              right: 0,
              top: topPadding,
              height: kToolbarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back to Home',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Daily Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    color: isSelected
                        ? _colors[i]
                        : Colors.transparent,
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
// +Add Details button
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
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '+Add Details',
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
//
// FIX: Removed the Expanded that was previously wrapping GestureDetector
// inside this widget. Expanded is only valid as a direct child of Row/Column/
// Flex. Placing it here caused "Expanded widgets must be placed inside a
// Flex" assertions. Width is now provided by the caller via Expanded in the
// parent Row.
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
    // GestureDetector is the root — no Expanded here.
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
                color:
                    eaten ? const Color(0xFFFF8A00) : Colors.black38,
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