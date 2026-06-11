import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/daily_summary_model.dart';

class DailySummaryDetailScreen extends StatefulWidget {
  final String summaryId;
  final String parentId;
  final String childId;
  final String childName;

  const DailySummaryDetailScreen({
    super.key,
    required this.summaryId,
    required this.parentId,
    required this.childId,
    required this.childName,
  });

  @override
  State<DailySummaryDetailScreen> createState() => _DailySummaryDetailScreenState();
}

class _DailySummaryDetailScreenState extends State<DailySummaryDetailScreen> {
  DailySummaryModel? _summary;
  bool _loading = true;
  String? _therapistName;
  DateTime? _lastEdited;
  Map<String, String> _questionTexts = {};

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('dailySummaries')
          .doc(widget.summaryId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _summary = DailySummaryModel.fromJson({...data, 'childId': widget.childId});
        _lastEdited = (data['updatedAt'] as Timestamp?)?.toDate() ?? _summary!.date;
        await _fetchTrackingQuestions();
        await _fetchTherapistName();
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchTrackingQuestions() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('trackingQuestions')
          .get();

      final map = <String, String>{};
      for (final doc in snap.docs) {
        final text = doc.data()['questionText'] as String?;
        if (text != null) map[doc.id] = text;
      }
      _questionTexts = map;
    } catch (e) {
      debugPrint('Error fetching tracking questions: $e');
    }
  }

  Future<void> _fetchTherapistName() async {
    try {
      final childDoc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .get();
      final linkedTherapistId = childDoc.data()?['linkedTherapistId'] as String?;
      if (linkedTherapistId != null && linkedTherapistId.isNotEmpty) {
        final therapistDoc = await FirebaseFirestore.instance.collection('therapists').doc(linkedTherapistId).get();
        setState(() => _therapistName = therapistDoc.data()?['name'] as String? ?? 'Therapist');
      }
    } catch (_) {}
  }

  // Lock check: locked after midnight of the day it was logged
  bool get _isLocked {
    if (_summary == null) return true;
    final logDay = _summary!.date;
    final midnight = DateTime(logDay.year, logDay.month, logDay.day + 1);
    return DateTime.now().isAfter(midnight);
  }

  Future<void> _deleteSummary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Summary'),
        content: const Text('Are you sure you want to delete this log? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('dailySummaries')
          .doc(widget.summaryId)
          .delete();
      if (mounted) context.pop();
    }
  }

  String _ratingLabel(Rating r) => ['Bad', 'Poor', 'Average', 'Good', 'Excellent'][r.index];
  String _ratingEmoji(Rating r) => ['😡', '😟', '😐', '🙂', '😄'][r.index];

  String _formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Summary')),
        body: const Center(child: Text('Log not found.')),
      );
    }

    final s = _summary!;
    final dateStr = DateFormat('EEE d MMM yyyy').format(s.date);
    final sleepDuration = s.bedtime != null && s.wakeTime != null
        ? _calcSleepDuration(s.bedtime!, s.wakeTime!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textMain),
          onPressed: () => context.pop(),
        ),
        title: Text('Daily Summary', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondary),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('SUMMARY', style: AppTextStyles.tag.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + child
            Text('$dateStr · ${widget.childName}', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
            const SizedBox(height: 24),

            // ── SLEEP ─────────────────────────────────────────────────────────
            _SectionHeader(title: 'SLEEP'),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Sleep Quality',
              right: Row(
                children: [
                  _RatingDots(rating: s.sleepRating),
                  const SizedBox(width: 6),
                  Text('${s.sleepRating.index + 1}/5', style: AppTextStyles.body.copyWith(color: AppColors.textSubtle)),
                ],
              ),
            ),
            if (s.bedtime != null || s.wakeTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (s.bedtime != null) Expanded(child: _InfoBlock(label: 'Bedtime', value: _formatTime(s.bedtime!))),
                  if (s.wakeTime != null) Expanded(child: _InfoBlock(label: 'Wake', value: _formatTime(s.wakeTime!))),
                  if (sleepDuration != null) Expanded(child: _InfoBlock(label: 'Duration', value: sleepDuration)),
                ],
              ),
            ],
            _Divider(),

            // ── MORNING MOOD ──────────────────────────────────────────────────
            _SectionHeader(title: 'MORNING MOOD'),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Mood',
              right: Row(
                children: [
                  _RatingDots(rating: s.moodRating),
                  const SizedBox(width: 6),
                  Text('${s.moodRating.index + 1}/5', style: AppTextStyles.body.copyWith(color: AppColors.textSubtle)),
                ],
              ),
            ),
            _Divider(),

            // ── MEALS ─────────────────────────────────────────────────────────
            _SectionHeader(title: 'MEALS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MealCell(label: 'Breakfast', eaten: s.breakfastEaten, detail: s.breakfastDetails)),
                Expanded(child: _MealCell(label: 'Lunch', eaten: s.lunchEaten, detail: s.lunchDetails)),
                Expanded(child: _MealCell(label: 'Dinner', eaten: s.dinnerEaten, detail: s.dinnerDetails)),
              ],
            ),
            _Divider(),

            // ── ROUTINE ───────────────────────────────────────────────────────
            _SectionHeader(title: 'ROUTINE'),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Routine',
              right: Row(
                children: [
                  Icon(s.routineNormal ? Icons.check : Icons.close, size: 16, color: s.routineNormal ? AppColors.success : AppColors.error),
                  const SizedBox(width: 4),
                  Text(s.routineNormal ? 'Normal' : 'Disrupted',
                    style: AppTextStyles.body.copyWith(color: s.routineNormal ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            _Divider(),

            // ── THERAPIST QUESTIONS ───────────────────────────────────────────
            if (s.customAnswers.isNotEmpty) ...[
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary)),
                  const SizedBox(width: 6),
                  Text('ADDED BY THERAPIST', style: AppTextStyles.tag.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ...s.customAnswers.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary20,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_questionTexts[entry.key] ?? entry.key, style: AppTextStyles.body)),
                      Text(
                        entry.value?.toString() ?? '-',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )).toList(),
              _Divider(),
            ],

            // Therapist comment
            if (s.therapistComments != null && s.therapistComments!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary20,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.secondary,
                          child: Text(
                            _therapistName?.isNotEmpty == true ? _therapistName![0].toUpperCase() : 'T',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_therapistName ?? 'Therapist', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(s.therapistComments!, style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            if (s.notes != null && s.notes!.isNotEmpty) ...[
              Text('Notes', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
              const SizedBox(height: 4),
              Text(s.notes!, style: AppTextStyles.body),
              const SizedBox(height: 16),
            ],

            // Last edited + lock info
            if (_lastEdited != null)
              Text('Last edited: ${DateFormat('d MMM yyyy \'at\' hh:mm a').format(_lastEdited!)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(_isLocked ? Icons.lock_outline : Icons.lock_open_outlined, size: 13, color: AppColors.textSubtle),
                const SizedBox(width: 4),
                Text(
                  _isLocked ? 'This log is locked after midnight.' : 'Logs lock at midnight.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Edit + Delete buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLocked ? null : () {
                      context.push(Routes.dailySummary, extra: {
                        'parentId': widget.parentId,
                        'childId': widget.childId,
                        'childName': widget.childName,
                        'summaryId': widget.summaryId,
                        'existingSummary': s,
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: _isLocked ? AppColors.borderInactive : AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    icon: Icon(Icons.edit_outlined, size: 18, color: _isLocked ? AppColors.textDisabled : AppColors.primary),
                    label: Text('Edit', style: TextStyle(color: _isLocked ? AppColors.textDisabled : AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLocked ? null : _deleteSummary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: _isLocked ? AppColors.borderInactive : AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    icon: Icon(Icons.delete_outline, size: 18, color: _isLocked ? AppColors.textDisabled : AppColors.error),
                    label: Text('Delete', style: TextStyle(color: _isLocked ? AppColors.textDisabled : AppColors.error, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _calcSleepDuration(DateTime bedtime, DateTime wakeTime) {
    var diff = wakeTime.difference(bedtime);
    if (diff.isNegative) diff = Duration(hours: 24) + diff;
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h} hrs';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700, letterSpacing: 0.8));
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: AppColors.dividerLight),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget right;
  const _DetailRow({required this.label, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body),
        right,
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MealCell extends StatelessWidget {
  final String label;
  final bool eaten;
  final String? detail;
  const _MealCell({required this.label, required this.eaten, this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(eaten ? Icons.check : Icons.close, size: 14, color: eaten ? AppColors.success : AppColors.textDisabled),
            const SizedBox(width: 4),
            Text(eaten ? 'Eaten' : 'Skipped', style: AppTextStyles.caption.copyWith(color: eaten ? AppColors.success : AppColors.textDisabled, fontWeight: FontWeight.w600)),
          ],
        ),
        if (detail != null && detail!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(detail!, style: AppTextStyles.tag.copyWith(color: AppColors.textSubtle), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}

class _RatingDots extends StatelessWidget {
  final Rating rating;
  const _RatingDots({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) => Container(
        width: 10, height: 10,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i <= rating.index ? AppColors.primary : AppColors.inputFill,
        ),
      )),
    );
  }
}