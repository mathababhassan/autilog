import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/child_model.dart';
import '../../../../shared/models/incident_model.dart';
import '../../../../shared/models/daily_summary_model.dart';
import '../../../../shared/models/positive_moment_model.dart';
import '../../../incident_log/presentation/screens/incident_detail_screen.dart';
import '../../../positive_moment/presentation/screens/positive_moment_detail_screen.dart';
import '../../../positive_moment/positive_moment_route_args.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class LogHistoryScreen extends StatefulWidget {
  final String childId;

  const LogHistoryScreen({super.key, required this.childId});

  @override
  State<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends State<LogHistoryScreen> {
  String? _selectedChildId;
  String _filterType = 'ALL'; // ALL, SUMMARY, INCIDENT, POSITIVE
  bool _calendarMode = true;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _calendarExpanded = true;

  // Cache of all logs fetched
  List<_LogEntry> _allLogs = [];
  bool _loading = true;
  String? _parentId;
  Map<String, ChildModel> _childModels = {};

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _parentId = FirebaseAuth.instance.currentUser?.uid;
    if (_parentId != null) {
      _fetchLogs();
    }
  }

  Future<void> _fetchLogs() async {
  if (_parentId == null) return;
  setState(() => _loading = true);

  // Auto-select first child if none selected
  if (_selectedChildId == null || _selectedChildId!.isEmpty) {
    try {
      final childSnap = await FirebaseFirestore.instance
          .collection('parents')
          .doc(_parentId)
          .collection('children')
          .limit(1)
          .get();
      if (childSnap.docs.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      _selectedChildId = childSnap.docs.first.id;
    } catch (_) {
      setState(() => _loading = false);
      return;
    }
  }

  final db = FirebaseFirestore.instance;
  final base = db.collection('parents').doc(_parentId).collection('children').doc(_selectedChildId);
  final logs = <_LogEntry>[];

  try {
    final summaries = await base.collection('dailySummaries').orderBy('date', descending: true).get();
    for (final doc in summaries.docs) {
      final data = doc.data();
      final model = DailySummaryModel.fromJson({...data, 'childId': _selectedChildId!});
      logs.add(_LogEntry(
        id: doc.id,
        type: 'SUMMARY',
        date: model.date,
        createdAt: model.date,
        summary: model,
        parentId: _parentId!,
        childId: _selectedChildId!,
      ));
    }
  } catch (_) {}

  try {
    final incidents = await base.collection('incidents').orderBy('createdAt', descending: true).get();
    for (final doc in incidents.docs) {
      final model = IncidentModel.fromMap(doc.data(), doc.id);
      logs.add(_LogEntry(
        id: doc.id,
        type: 'INCIDENT',
        date: model.date,
        createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? model.date,
        incident: model,
        parentId: _parentId!,
        childId: _selectedChildId!,
      ));
    }
  } catch (_) {}

  try {
    final moments = await base.collection('positiveMoments').orderBy('createdAt', descending: true).get();
    for (final doc in moments.docs) {
      final model = PositiveMomentModel.fromMap(doc.data(), doc.id);
      logs.add(_LogEntry(
        id: doc.id,
        type: 'POSITIVE',
        date: model.date,
        createdAt: model.createdAt,
        moment: model,
        parentId: _parentId!,
        childId: _selectedChildId!,
      ));
    }
  } catch (_) {}

  logs.sort((a, b) => b.date.compareTo(a.date));
  setState(() {
    _allLogs = logs;
    _loading = false;
  });
}

  List<_LogEntry> get _filteredLogs {
    var logs = _allLogs;
    if (_filterType != 'ALL') {
      logs = logs.where((l) => l.type == _filterType).toList();
    }
    if (_selectedDay != null) {
      logs = logs.where((l) =>
        l.date.year == _selectedDay!.year &&
        l.date.month == _selectedDay!.month &&
        l.date.day == _selectedDay!.day
      ).toList();
    }
    return logs;
  }

  // Get log types for a specific day (for calendar dots)
  Set<String> _typesForDay(DateTime day) {
    return _allLogs
        .where((l) => l.date.year == day.year && l.date.month == day.month && l.date.day == day.day)
        .map((l) => l.type)
        .toSet();
  }

  void _onChildChanged(String id, Map<String, ChildModel> models) {
    setState(() {
      _selectedChildId = id;
      _selectedDay = null;
    });
    _fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _parentId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('parents').doc(uid).collection('children').snapshots(),
      builder: (context, childSnap) {
        final childDocs = childSnap.data?.docs ?? [];
        final childModels = <String, ChildModel>{};
        for (final doc in childDocs) {
          final data = doc.data() as Map<String, dynamic>;
          childModels[doc.id] = ChildModel.fromMap({...data, 'parentId': uid}, doc.id);
        }

        if (_selectedChildId == null && childDocs.isNotEmpty) {
          _selectedChildId = childDocs.first.id;
        }

        final selectedChild = _selectedChildId != null ? childModels[_selectedChildId] : null;

        return Scaffold(
          backgroundColor: AppColors.surfaceDefault,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, selectedChild?.name),
                if (childDocs.length > 1)
                  _buildChildDropdown(childDocs, childModels, uid),
                _buildViewToggle(),
                if (!_calendarMode)
                  _buildFilterChips(),
                if (_calendarMode)
                  _buildCalendar()
                else
                  Expanded(child: _buildLogList(context, selectedChild, childModels)),
              ],
            ),
          ),
          bottomNavigationBar: widget.childId.isNotEmpty ? _buildBottomNav(context) : null,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String? childName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.borderInactive)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text('Log History', style: AppTextStyles.heading1),
          ),
          if (childName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary20,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(childName, style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildChildDropdown(List<QueryDocumentSnapshot> childDocs, Map<String, ChildModel> models, String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Child', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedChildId != null && _selectedChildId!.isNotEmpty ? _selectedChildId : null,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondary),
                items: childDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] as String? ?? 'Child';
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 14, backgroundColor: AppColors.secondary20, child: Icon(Icons.child_care, size: 16, color: AppColors.secondary)),
                        const SizedBox(width: 10),
                        Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) _onChildChanged(id, models);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _ViewToggleBtn(label: 'Calendar', icon: Icons.calendar_today_outlined, active: _calendarMode, onTap: () => setState(() { _calendarMode = true; _calendarExpanded = true; })),
          const SizedBox(width: 10),
          _ViewToggleBtn(label: 'List', icon: Icons.list_outlined, active: !_calendarMode, onTap: () => setState(() { _calendarMode = false; _selectedDay = null; })),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['ALL', 'SUMMARY', 'INCIDENT', 'POSITIVE'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: filters.map((f) {
          final active = _filterType == f;
          final color = f == 'INCIDENT' ? AppColors.accentRed : f == 'POSITIVE' ? AppColors.primary : AppColors.secondary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterType = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? color : AppColors.surfaceDefault,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? color : AppColors.borderInactive),
                ),
                child: Text(
                  f,
                  style: AppTextStyles.tag.copyWith(
                    color: active ? AppColors.textWhite : AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderInactive),
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                child: const Icon(Icons.chevron_left, color: AppColors.textMain),
              ),
              Text(DateFormat('MMMM yyyy').format(_focusedMonth), style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                child: const Icon(Icons.chevron_right, color: AppColors.textMain),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.secondary, label: 'Summary'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.accentRed, label: 'Incident'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.primary, label: 'Positive'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.borderInactive, label: 'No log'),
            ],
          ),
          const SizedBox(height: 10),
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
              Expanded(child: Center(child: Text(d, style: AppTextStyles.tag.copyWith(color: AppColors.textSubtle))))
            ).toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 0, childAspectRatio: 1),
            itemCount: (startWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday - 1) return const SizedBox();
              final day = index - (startWeekday - 1) + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final types = _typesForDay(date);
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == date.year &&
                  _selectedDay!.month == date.month &&
                  _selectedDay!.day == date.day;
              final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedDay = null;
                  } else {
                    _selectedDay = date;
                  }
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? AppColors.textWhite : AppColors.textMain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (types.contains('SUMMARY')) _CalDot(color: AppColors.secondary),
                        if (types.contains('INCIDENT')) _CalDot(color: AppColors.accentRed),
                        if (types.contains('POSITIVE')) _CalDot(color: AppColors.primary),
                        if (types.isEmpty) _CalDot(color: AppColors.borderInactive),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text('Tap any day to view its logs', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
        ],
      ),
    );
  }

  Widget _buildCalendarToggle() {
    return GestureDetector(
      onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_calendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSubtle, size: 18),
            Text(_calendarExpanded ? 'Hide calendar' : 'Show calendar', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(BuildContext context, ChildModel? selectedChild, Map<String, ChildModel> childModels) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final logs = _filteredLogs;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 56, color: AppColors.borderInactive),
            const SizedBox(height: 12),
            Text('No logs found', style: AppTextStyles.subtitle.copyWith(color: AppColors.textDisabled)),
            const SizedBox(height: 4),
            Text('Try a different filter or date', style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder)),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<_LogEntry>>{};
    for (final log in logs) {
      final key = DateFormat('EEE d MMM yyyy').format(log.date);
      grouped.putIfAbsent(key, () => []).add(log);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final dateKey = grouped.keys.elementAt(i);
        final dayLogs = grouped[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(dateKey, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
            ),
            ...dayLogs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildLogCard(context, log, selectedChild, childModels),
            )),
          ],
        );
      },
    );
  }

  Widget _buildLogCard(BuildContext context, _LogEntry log, ChildModel? selectedChild, Map<String, ChildModel> childModels) {
    if (log.type == 'SUMMARY' && log.summary != null) {
      final s = log.summary!;
      final moodLabel = ['Bad', 'Poor', 'Average', 'Good', 'Excellent'][s.moodRating.index];
      final sleepLabel = ['Bad', 'Poor', 'Average', 'Good', 'Excellent'][s.sleepRating.index];
      return _LogCard(
        type: 'SUMMARY',
        typeColor: AppColors.secondary,
        title: 'Sleep $sleepLabel · Mood $moodLabel',
        detail: [
          if (s.breakfastEaten || s.lunchEaten || s.dinnerEaten) 'Meals eaten',
          if (!s.breakfastEaten && !s.lunchEaten && !s.dinnerEaten) 'Meals skipped',
          if (s.routineNormal) 'Normal routine' else 'Disrupted routine',
        ].join(' · '),
        onTap: () => context.push(Routes.dailySummaryDetail, extra: {
          'summaryId': log.id,
          'parentId': log.parentId,
          'childId': log.childId,
          'childName': selectedChild?.name ?? '',
        }),
      );
    }

    if (log.type == 'INCIDENT' && log.incident != null) {
      final inc = log.incident!;
      final child = childModels[log.childId] ?? selectedChild;
      return _LogCard(
        type: 'INCIDENT',
        typeColor: AppColors.accentRed,
        title: inc.behaviorTypes.isNotEmpty ? inc.behaviorTypes.first : 'Behavioral Incident',
        detail: 'Severity ${inc.behaviorSeverity}/5',
        onTap: child == null ? null : () => context.push(Routes.incidentDetail, extra: IncidentDetailArgs(incidentId: inc.id, child: child)),
      );
    }

    if (log.type == 'POSITIVE' && log.moment != null) {
      final mom = log.moment!;
      return _LogCard(
        type: 'POSITIVE',
        typeColor: AppColors.primary,
        title: mom.behaviorTypes.isNotEmpty ? mom.behaviorTypes.first : 'Positive Moment',
        detail: 'Rating ${mom.positiveBehaviorRating}/5',
        onTap: () => context.push(Routes.positiveMomentDetail, extra: PositiveMomentDetailArgs(
          momentId: mom.id,
          parentId: log.parentId,
          childId: log.childId,
          childName: selectedChild?.name ?? '',
        )),
      );
    }

    return const SizedBox.shrink();
  }

  
  Widget _buildBottomNav(BuildContext context) {
  final childId = _selectedChildId ?? '';
  final childName = _selectedChildId != null ? _childModels[_selectedChildId]?.name ?? '' : '';
  
  return BottomNavigationBar(
    currentIndex: 1,
    onTap: (index) {
      if (index == 0) {
        context.go(Routes.parentHome);
      } else if (index == 1) {
        // Already on Log History
      } else if (index == 2) {
        context.push(Routes.parentSessions, extra: {
          'childId': childId,
          'childName': childName,
        });
      }
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
  );
}
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Entry Model
// ─────────────────────────────────────────────────────────────────────────────

class _LogEntry {
  final String id;
  final String type;
  final DateTime date;
  final DateTime createdAt;
  final String parentId;
  final String childId;
  final DailySummaryModel? summary;
  final IncidentModel? incident;
  final PositiveMomentModel? moment;

  const _LogEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.parentId,
    required this.childId,
    this.summary,
    this.incident,
    this.moment,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ViewToggleBtn({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.borderInactive),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? AppColors.textWhite : AppColors.textMain),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: active ? AppColors.textWhite : AppColors.textMain, fontWeight: FontWeight.w600)),
          ],
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
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.tag.copyWith(color: AppColors.textSubtle)),
      ],
    );
  }
}

class _CalDot extends StatelessWidget {
  final Color color;
  const _CalDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5, height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _LogCard extends StatelessWidget {
  final String type;
  final Color typeColor;
  final String title;
  final String detail;
  final VoidCallback? onTap;

  const _LogCard({required this.type, required this.typeColor, required this.title, required this.detail, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: typeColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type, style: AppTextStyles.tag.copyWith(color: typeColor, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(title, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(detail, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}