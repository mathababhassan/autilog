import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';

class TherapistReportsScreen extends StatefulWidget {
  const TherapistReportsScreen({super.key});

  @override
  State<TherapistReportsScreen> createState() => _TherapistReportsScreenState();
}

class _TherapistReportsScreenState extends State<TherapistReportsScreen> {
  int _rangeDays = 7; // 7 or 30
  bool _loading = true;

  // Aggregates
  int _totalIncidents = 0;
  double _avgSleep = 0;
  String _topTrigger = '--';
  Map<String, int> _triggerCounts = {};
  List<FlSpot> _severitySpots = [];
  List<FlSpot> _sleepSpots = [];
  List<String> _dateLabels = [];
  int _patientCount = 0;

  // AI summary
  String _aiSummary = '';
  String _aiFocus = '';
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final therapistId = FirebaseAuth.instance.currentUser?.uid;
    if (therapistId == null) {
      setState(() => _loading = false);
      return;
    }

    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    final fs = FirebaseFirestore.instance;

    // 1. Get patients
    final patientsSnap = await fs
        .collection('therapists')
        .doc(therapistId)
        .collection('patients')
        .get();

    _patientCount = patientsSnap.docs.length;

    int totalIncidents = 0;
    final triggerCounts = <String, int>{};
    final sleepByDay = <String, List<int>>{};
    final severityByDay = <String, List<int>>{};

    // 2. For each patient, read incidents + daily summaries
    for (final patientDoc in patientsSnap.docs) {
      final data = patientDoc.data();
      final parentId = data['parentId'] as String?;
      final childId = patientDoc.id;
      if (parentId == null) continue;

      final childBase = fs
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId);

      // Incidents
      try {
        final incidentsSnap = await childBase
            .collection('incidents')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
            .get();

        for (final inc in incidentsSnap.docs) {
          final incData = inc.data();
          totalIncidents++;

          final severity = incData['behaviorSeverity'] as int? ?? 0;
          final date = (incData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dayKey = DateFormat('MM-dd').format(date);
          severityByDay.putIfAbsent(dayKey, () => []).add(severity);

          final triggers = (incData['antecedentTriggers'] as List<dynamic>?)?.cast<String>() ?? [];
          for (final t in triggers) {
            triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
          }
        }
      } catch (_) {}

      // Daily summaries
      try {
        final summariesSnap = await childBase
            .collection('dailySummaries')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
            .get();

        for (final sum in summariesSnap.docs) {
          final sumData = sum.data();
          final sleep = sumData['sleepRating'] as int? ?? 0;
          final date = (sumData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dayKey = DateFormat('MM-dd').format(date);
          if (sleep > 0) sleepByDay.putIfAbsent(dayKey, () => []).add(sleep);
        }
      } catch (_) {}
    }

    // 3. Compute aggregates
    final allSleep = sleepByDay.values.expand((e) => e).toList();
    final avgSleep = allSleep.isEmpty
        ? 0.0
        : allSleep.reduce((a, b) => a + b) / allSleep.length;

    String topTrigger = '--';
    if (triggerCounts.isNotEmpty) {
      topTrigger = triggerCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    // 4. Build chart series — sorted day keys
    final allDays = <String>{...severityByDay.keys, ...sleepByDay.keys}.toList()..sort();
    final severitySpots = <FlSpot>[];
    final sleepSpots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < allDays.length; i++) {
      final day = allDays[i];
      labels.add(day);

      final sevList = severityByDay[day] ?? [];
      final sevAvg = sevList.isEmpty ? 0.0 : sevList.reduce((a, b) => a + b) / sevList.length;
      severitySpots.add(FlSpot(i.toDouble(), sevAvg));

      final slpList = sleepByDay[day] ?? [];
      final slpAvg = slpList.isEmpty ? 0.0 : slpList.reduce((a, b) => a + b) / slpList.length;
      sleepSpots.add(FlSpot(i.toDouble(), slpAvg));
    }

    if (mounted) {
      setState(() {
        _totalIncidents = totalIncidents;
        _avgSleep = avgSleep;
        _topTrigger = topTrigger;
        _triggerCounts = triggerCounts;
        _severitySpots = severitySpots;
        _sleepSpots = sleepSpots;
        _dateLabels = labels;
        _loading = false;
      });
    }
  }

  Future<void> _generateAISummary() async {
    setState(() => _aiLoading = true);

    try {
      final stats = {
        'periodDays': _rangeDays,
        'patientCount': _patientCount,
        'totalIncidents': _totalIncidents,
        'avgSleepQuality': _avgSleep.toStringAsFixed(1),
        'topTrigger': _topTrigger,
        'triggerBreakdown': _triggerCounts,
      };

      final callable = FirebaseFunctions.instance.httpsCallable('getReportSummary');
      final result = await callable.call({'stats': stats});
      final data = result.data as Map;

      if (mounted) {
        setState(() {
          _aiSummary = data['summary'] as String? ?? '';
          _aiFocus = data['focusArea'] as String? ?? '';
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSummary = 'Could not generate summary. Please try again.';
          _aiLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text('Reports', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range toggle
                    Row(
                      children: [
                        _RangeChip(
                          label: 'Last 7 Days',
                          active: _rangeDays == 7,
                          onTap: () {
                            setState(() => _rangeDays = 7);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        _RangeChip(
                          label: 'Last 30 Days',
                          active: _rangeDays == 30,
                          onTap: () {
                            setState(() => _rangeDays = 30);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // AI summary card
                    _AISummaryCard(
                      summary: _aiSummary,
                      focus: _aiFocus,
                      loading: _aiLoading,
                      onRefresh: _generateAISummary,
                    ),
                    const SizedBox(height: 20),

                    // Stat cards
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'Total Incidents', value: '$_totalIncidents', subtitle: 'all patients')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Avg Sleep', value: _avgSleep > 0 ? '${_avgSleep.toStringAsFixed(1)}/5' : '--', subtitle: 'all patients')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(label: 'Top Trigger', value: _topTrigger, subtitle: 'most common, all patients', wide: true),
                    const SizedBox(height: 20),

                    // Line chart
                    Text('Severity & Sleep Over Time', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _LineChartCard(
                      severitySpots: _severitySpots,
                      sleepSpots: _sleepSpots,
                      labels: _dateLabels,
                    ),
                    const SizedBox(height: 20),

                    // Bar chart
                    Text('Most Common Triggers', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _TriggerBarChart(triggerCounts: _triggerCounts),
                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        'Based on data from $_patientCount patient${_patientCount == 1 ? '' : 's'}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

// ─── AI Summary Card ──────────────────────────────────────────

class _AISummaryCard extends StatelessWidget {
  final String summary;
  final String focus;
  final bool loading;
  final VoidCallback onRefresh;

  const _AISummaryCard({
    required this.summary,
    required this.focus,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary20,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'AI Practice Summary',
                style: AppTextStyles.subtitle.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: loading ? null : onRefresh,
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
                    : Icon(Icons.refresh, color: AppColors.secondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary.isEmpty && !loading)
            Text(
              'Tap refresh to generate an AI summary of your caseload for this period.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            )
          else if (summary.isNotEmpty) ...[
            Text(summary, style: AppTextStyles.body),
            if (focus.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDefault,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.center_focus_strong, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(focus, style: AppTextStyles.caption)),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final bool wide;

  const _StatCard({required this.label, required this.value, required this.subtitle, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderInactive),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.tag.copyWith(color: AppColors.textSubtle, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
        ],
      ),
    );
  }
}

// ─── Line Chart ───────────────────────────────────────────────

class _LineChartCard extends StatelessWidget {
  final List<FlSpot> severitySpots;
  final List<FlSpot> sleepSpots;
  final List<String> labels;

  const _LineChartCard({required this.severitySpots, required this.sleepSpots, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderInactive),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.primary, label: 'Severity'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.secondary, label: 'Sleep Quality'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: severitySpots.isEmpty && sleepSpots.isEmpty
                ? Center(child: Text('No data for this period', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 5,
                      gridData: FlGridData(show: true, horizontalInterval: 1, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 28),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                              // Show only some labels to avoid crowding
                              if (labels.length > 7 && i % 3 != 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(labels[i], style: AppTextStyles.tag.copyWith(color: AppColors.textSubtle, fontSize: 9)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: severitySpots,
                          color: AppColors.primary,
                          barWidth: 3,
                          isCurved: true,
                          dotData: const FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: sleepSpots,
                          color: AppColors.secondary,
                          barWidth: 3,
                          isCurved: true,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────

class _TriggerBarChart extends StatelessWidget {
  final Map<String, int> triggerCounts;

  const _TriggerBarChart({required this.triggerCounts});

  @override
  Widget build(BuildContext context) {
    final sorted = triggerCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderInactive),
      ),
      child: top.isEmpty
          ? Center(child: Text('No triggers logged this period', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)))
          : Column(
              children: top.map((e) {
                final maxVal = top.first.value;
                final fraction = maxVal == 0 ? 0.0 : e.value / maxVal;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(e.key, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: fraction,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ─── Small Widgets ────────────────────────────────────────────

class _RangeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RangeChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: active ? AppColors.textWhite : AppColors.textMain,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, label: 'Home', onTap: () => context.go(Routes.therapistHome)),
              _NavItem(icon: Icons.people_outline, label: 'Patients', onTap: () => context.go(Routes.therapistPatients)),
              const _NavItem(icon: Icons.calendar_month_outlined, label: 'Sessions'),
              _NavItem(icon: Icons.bar_chart, label: 'Reports', active: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSubtle;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.tag.copyWith(color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
