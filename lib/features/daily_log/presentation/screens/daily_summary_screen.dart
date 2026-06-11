import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../features/daily_log/bloc/daily_summary_bloc.dart';
import '../../../../../features/daily_log/data/daily_summary_repository.dart';
import '../../../../../shared/models/daily_summary_model.dart';
import '../widgets/sleep_details_sheet.dart';
import '../widgets/summary_saved_dialog.dart';
import '../../../../../core/theme/theme.dart';
import '../widgets/meal_details_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Question Model
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicQuestion {
  final String id;
  final String questionText;
  final String answerType;
  final String status;

  _DynamicQuestion({
    required this.id,
    required this.questionText,
    required this.answerType,
    required this.status,
  });
}

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
  String? _breakfastDetails;
  String? _lunchDetails;
  String? _dinnerDetails;
  bool? _routineNormal;
  bool? _hadScreenTime;
  final _screenTimeController = TextEditingController();
  bool? _tookMedication;
  final _notesController = TextEditingController();
  String? _therapistName;

  // Dynamic questions
  List<_DynamicQuestion> _dynamicQuestions = [];
  bool _loadingQuestions = true;
  Map<String, dynamic> _questionAnswers = {};

  @override
  void initState() {
    super.initState();
    _fetchTherapistName();
    _fetchTrackingQuestions();
  }

  @override
  void dispose() {
    _screenTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrackingQuestions() async {
    setState(() => _loadingQuestions = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('trackingQuestions')
          .where('status', isEqualTo: 'active')
          .get();

      final questions = snapshot.docs.map((doc) {
        final data = doc.data();
        return _DynamicQuestion(
          id: doc.id,
          questionText: data['questionText'] as String? ?? '',
          answerType: data['answerType'] as String? ?? 'yes_no',
          status: data['status'] as String? ?? 'active',
        );
      }).toList();

      setState(() {
        _dynamicQuestions = questions;
        _loadingQuestions = false;
      });
    } catch (e) {
      print('Error fetching questions: $e');
      setState(() => _loadingQuestions = false);
    }
  }

  DateTime? _toDateTime(TimeOfDay? time) {
    if (time == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  void _submit() {
  // Validate Sleep Rating
  if (_sleepRating == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please rate how well your child slept')),
    );
    return;
  }

  // Validate Morning Mood
  if (_moodRating == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please rate your child\'s morning mood')),
    );
    return;
  }

  // Validate Routine
  if (_routineNormal == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please indicate if routine was normal')),
    );
    return;
  }

  // Validate at least one meal was marked Eaten
  if (!_breakfastEaten && !_lunchEaten && !_dinnerEaten) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please mark at least one meal as eaten')),
    );
    return;
  }

  // Validate dynamic questions (only if they exist)
  for (final question in _dynamicQuestions) {
    final answer = _questionAnswers[question.id];
    
    if (answer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer: ${question.questionText}')),
      );
      return;
    }
    
    // Additional validation based on answer type
    if (question.answerType == 'number' && answer is double && answer <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid number for: ${question.questionText}')),
      );
      return;
    }
    
    if (question.answerType == 'rating' && answer is int && (answer < 1 || answer > 5)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid rating for: ${question.questionText}')),
      );
      return;
    }
    
    if (question.answerType == 'time' && answer is String && answer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid time for: ${question.questionText}')),
      );
      return;
    }
    
    if (question.answerType == 'text' && answer is String && answer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide an answer for: ${question.questionText}')),
      );
      return;
    }
  }

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
    breakfastDetails: _breakfastDetails,
    lunchDetails: _lunchDetails,
    dinnerDetails: _dinnerDetails,
    routineNormal: _routineNormal ?? true,
    notes: _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim(),
    createdBy: uid,
    customAnswers: _questionAnswers,
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

  void _showAllMealDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MealDetailsSheet(
        breakfastEaten: _breakfastEaten,
        lunchEaten: _lunchEaten,
        dinnerEaten: _dinnerEaten,
        initialBreakfastDetails: _breakfastDetails,
        initialLunchDetails: _lunchDetails,
        initialDinnerDetails: _dinnerDetails,
        onSave: (breakfast, lunch, dinner) {
          setState(() {
            _breakfastDetails = breakfast;
            _lunchDetails = lunch;
            _dinnerDetails = dinner;
          });
        },
      ),
    );
  }

  void _fetchTherapistName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _therapistName = 'Dr. Sara');
      return;
    }

    try {
      final childDoc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .collection('children')
          .doc(widget.childId)
          .get();

      final linkedTherapistId = childDoc.data()?['linkedTherapistId'] as String?;
      if (linkedTherapistId != null && linkedTherapistId.isNotEmpty) {
        final therapistDoc = await FirebaseFirestore.instance
            .collection('therapists')
            .doc(linkedTherapistId)
            .get();
        final name = therapistDoc.data()?['name'] as String?;
        setState(() => _therapistName = name ?? 'Dr. Sara');
      } else {
        setState(() => _therapistName = 'Dr. Sara');
      }
    } catch (e) {
      setState(() => _therapistName = 'Dr. Sara');
    }
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
            builder: (_) => SummarySavedDialog(
              childId: widget.childId,
              childName: widget.childName,
              date: DateTime.now(),
            ),
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
                      if (_sleepRating != null)
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
                      if (_breakfastEaten || _lunchEaten || _dinnerEaten)
                        _AddDetailsButton(onTap: _showAllMealDetails),

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

                      // ── Dynamic Questions from Therapist ───────────────────
                      _SectionTitle('Added by ${_therapistName ?? "Dr. Sara"}'),
                      const SizedBox(height: 16),

                      if (_loadingQuestions)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_dynamicQuestions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No custom questions added by your therapist yet.',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        )
                      else
                        ..._dynamicQuestions.map((question) {
                          return _DynamicQuestionWidget(
                            question: question,
                            childName: widget.childName,
                            onAnswerChanged: (value) {
                              setState(() {
                                _questionAnswers[question.id] = value;
                              });
                            },
                          );
                        }).toList(),

                      const SizedBox(height: 28),

                      // ── Save button ───────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
            selectedItemColor: AppColors.primary,
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
// Dynamic Question Widget
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicQuestionWidget extends StatelessWidget {
  final _DynamicQuestion question;
  final String childName;
  final Function(dynamic) onAnswerChanged;

  const _DynamicQuestionWidget({
    required this.question,
    required this.childName,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        _buildAnswerInput(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnswerInput() {
    switch (question.answerType) {
      case 'yes_no':
        return _DynamicYesNoRow(
          onChanged: (value) => onAnswerChanged(value),
        );
      case 'number':
        return _DynamicNumberInput(
          onChanged: (value) => onAnswerChanged(value),
        );
      case 'text':
        return _DynamicTextInput(
          onChanged: (value) => onAnswerChanged(value),
        );
      case 'rating':
        return _DynamicRatingInput(
          onChanged: (value) => onAnswerChanged(value),
        );
      case 'time':
        return _DynamicTimeInput(
          onChanged: (value) => onAnswerChanged(value),
        );
      default:
        return _DynamicYesNoRow(
          onChanged: (value) => onAnswerChanged(value),
        );
    }
  }
}

// ─── Dynamic Answer Input Widgets ───────────────────────────────────────────

class _DynamicYesNoRow extends StatefulWidget {
  final Function(bool) onChanged;

  const _DynamicYesNoRow({required this.onChanged});

  @override
  State<_DynamicYesNoRow> createState() => _DynamicYesNoRowState();
}

class _DynamicYesNoRowState extends State<_DynamicYesNoRow> {
  bool? _value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DynamicYesNoChip(
          label: 'Yes',
          selected: _value == true,
          onTap: () {
            setState(() => _value = true);
            widget.onChanged(true);
          },
        ),
        const SizedBox(width: 12),
        _DynamicYesNoChip(
          label: 'No',
          selected: _value == false,
          onTap: () {
            setState(() => _value = false);
            widget.onChanged(false);
          },
        ),
      ],
    );
  }
}

class _DynamicYesNoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DynamicYesNoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary20 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : const Color(0xFF1A1A1A),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DynamicNumberInput extends StatelessWidget {
  final Function(double?) onChanged;

  const _DynamicNumberInput({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Enter a number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) {
        onChanged(double.tryParse(value));
      },
    );
  }
}

class _DynamicTextInput extends StatelessWidget {
  final Function(String) onChanged;

  const _DynamicTextInput({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Enter your answer...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: onChanged,
    );
  }
}

class _DynamicRatingInput extends StatefulWidget {
  final Function(int) onChanged;

  const _DynamicRatingInput({required this.onChanged});

  @override
  State<_DynamicRatingInput> createState() => _DynamicRatingInputState();
}

class _DynamicRatingInputState extends State<_DynamicRatingInput> {
  int? _selectedRating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = _selectedRating == rating;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedRating = rating);
            widget.onChanged(rating);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary20 : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$rating',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DynamicTimeInput extends StatelessWidget {
  final Function(String) onChanged;

  const _DynamicTimeInput({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Enter time (e.g., 7:30 PM)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: onChanged,
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 1.5 hours',
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
// Banner Delegate
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
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: Container(
        color: AppColors.primary,
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                            '',
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
// Section Title
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
// Rating Row
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
                    color: isSelected ? _colors[i] : Colors.transparent,
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
// Sleep Detail Chips
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
            backgroundColor: AppColors.primary20,
            labelStyle: const TextStyle(fontSize: 12, color: AppColors.primary),
            side: const BorderSide(color: AppColors.primary),
          ),
        if (wakeTime != null)
          Chip(
            label: Text('Wake: ${_fmt(wakeTime!)}'),
            backgroundColor: AppColors.primary20,
            labelStyle: const TextStyle(fontSize: 12, color: AppColors.primary),
            side: const BorderSide(color: AppColors.primary),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Details Button
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary20,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '+Add Details',
            style: TextStyle(
              color: AppColors.primary,
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
// Meal Card
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
          color: eaten ? AppColors.primary20 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: eaten ? AppColors.primary : const Color(0xFFE0E0E0),
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
                color: eaten ? AppColors.primary : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              eaten ? 'Eaten' : 'Skipped',
              style: TextStyle(
                fontSize: 11,
                color: eaten ? AppColors.primary : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yes / No Row
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary20 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : const Color(0xFF1A1A1A),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}