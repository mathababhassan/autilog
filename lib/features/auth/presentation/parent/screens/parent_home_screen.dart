import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../shared/widgets/notification_bell.dart';
import '../../../../../features/incident_log/presentation/widgets/log_type_sheet.dart';
import '../../../../../features/ai_insights/presentation/widgets/ai_insights_preview.dart';
import '../../../../../features/log_history/presentation/screens/log_history_screen.dart';
import '../../../../../features/sessions/data/session_repository.dart';
import '../../../../../shared/models/session_model.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;
  String? _selectedChildId;
  String _selectedChildName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: switch (_currentIndex) {
        0 => _DashboardTab(
            onChildSelected: (id, name) {
              _selectedChildId = id;
              _selectedChildName = name;
            },
          ),
        1 => const _LogHistoryTab(),
        _ => const _PlaceholderTab(),
      },
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2) {
            setState(() => _currentIndex = 0);
            context.push(Routes.parentSessions, extra: {
              'childId': _selectedChildId ?? '',
              'childName': _selectedChildName,
            });
          } else {
            setState(() => _currentIndex = i);
          }
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab({required this.onChildSelected});

  final void Function(String childId, String childName) onChildSelected;

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String? _selectedChildId;

  Future<SessionModel?> _fetchNextSession(String childId) async {
    try {
      final now = DateTime.now();
      final sessions = await SessionRepository().fetchSessionsForChild(childId);
      final upcoming = sessions
          .where((s) => s.status == 'upcoming' && s.scheduledAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return upcoming.isEmpty ? null : upcoming.first;
    } catch (_) {
      return null;
    }
  }

  String _weekday(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  String _month(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[d.month - 1];
  }

  String _formatTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .snapshots(),
      builder: (context, parentSnap) {
        final parentName = parentSnap.hasData && parentSnap.data!.exists
            ? (parentSnap.data!.data() as Map<String, dynamic>)['name']
                      as String? ??
                  'Parent'
            : 'Parent';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('parents')
              .doc(uid)
              .collection('children')
              .snapshots(),
          builder: (context, childSnap) {
            final children = childSnap.hasData
                ? childSnap.data!.docs
                : <QueryDocumentSnapshot>[];
            final hasChild = children.isNotEmpty;

            if (hasChild && _selectedChildId == null) {
              _selectedChildId = children.first.id;
            }

            // Notify parent widget of selected child
            if (hasChild && _selectedChildId != null) {
             final doc = children.firstWhere(
  (c) => c.id == _selectedChildId,
);
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? '';
              widget.onChildSelected(_selectedChildId!, name);
            }

            final selectedChildDoc = hasChild
                ? children.where((c) => c.id == _selectedChildId).firstOrNull
                : null;
            final selectedChildData =
                selectedChildDoc?.data() as Map<String, dynamic>?;
            final selectedChildName =
                selectedChildData?['name'] as String? ?? '';

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar(context, parentName)),

                if (children.length > 1)
                  SliverToBoxAdapter(child: _buildChildSwitcher(children)),

                if (!hasChild) ...[
                  SliverToBoxAdapter(child: _buildNoChildBanner(context)),
                  SliverToBoxAdapter(child: _buildEmptySummaryCards()),
                  SliverToBoxAdapter(child: _buildDisabledActions()),
                  SliverToBoxAdapter(child: _buildEmptyActivity()),
                  SliverToBoxAdapter(child: _buildEmptyInsights()),
                ] else ...[
                  SliverToBoxAdapter(
                    child: _buildSummaryCards(uid!, _selectedChildId!),
                  ),
                  SliverToBoxAdapter(
                    child: _buildActions(context, selectedChildName),
                  ),
                  SliverToBoxAdapter(
                    child: _buildRecentActivity(uid, _selectedChildId!),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: AIInsightsPreview(
                        childId: _selectedChildId ?? '',
                        childName: selectedChildName,
                      ),
                    ),
                  ),
                ],

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 32,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, String parentName) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFF8A00),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/autilog_logo.png', width: 22, height: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'AutiLog',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NotificationBell(
                    route: Routes.parentNotifications,
                    isTherapist: false,
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.push(Routes.parentProfile),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$greeting, $parentName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSwitcher(List<QueryDocumentSnapshot> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF8A00), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedChildId,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFFF8A00),
            ),
            items: children.map((child) {
              final data = child.data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? 'Child';
              final age = data['age'] as int? ?? 0;
              return DropdownMenuItem<String>(
                value: child.id,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFFFFE0B2),
                      child: Icon(
                        Icons.child_care,
                        size: 16,
                        color: Color(0xFFFF8A00),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$name  •  Age $age',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (id) {
              if (id != null) {
                setState(() => _selectedChildId = id);
                final data = children
                    .firstWhere((c) => c.id == id)
                    .data() as Map<String, dynamic>;
                widget.onChildSelected(id, data['name'] as String? ?? '');
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoChildBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF8A00), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFF8A00), size: 22),
                SizedBox(width: 8),
                Text(
                  'No child profile yet',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'You need a child profile to start logging. It only takes a minute.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(Routes.childRegistration),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('ADD CHILD PROFILE',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
              child: _SummaryCard(
                  title: 'Logs This Week',
                  value: '— —',
                  subtitle: 'Add a child to start')),
          const SizedBox(width: 12),
          Expanded(
              child: _SummaryCard(
                  title: 'Upcoming Session',
                  value: '— —',
                  subtitle: 'Add a child to start')),
        ],
      ),
    );
  }

  Widget _buildDisabledActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          _ActionButton(
            label: "LOG TODAY'S SUMMARY",
            icon: Icons.edit_note_rounded,
            enabled: true,
            onTap: () {
              final id = _selectedChildId;
              if (id == null || id.isEmpty) return;
              context.push(Routes.dailySummary, extra: id);
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
              label: 'LOG AN INCIDENT',
              icon: Icons.warning_amber_rounded,
              enabled: false,
              onTap: null,
              secondary: true),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12)),
            child: const Text(
                'No activity yet. Add a child profile and start logging to see your activity here.',
                style: TextStyle(color: Colors.black45, fontSize: 14),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInsights() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Insights',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12)),
            child: const Text(
                'Insights will appear after 7 days of logging. Add a child profile to begin.',
                style: TextStyle(color: Colors.black45, fontSize: 14),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(String uid, String childId) {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parents')
                  .doc(uid)
                  .collection('children')
                  .doc(childId)
                  .collection('dailySummaries')
                  .where('date',
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(weekStart))
                  .where('date',
                      isLessThan: Timestamp.fromDate(weekEnd))
                  .snapshots(),
              builder: (context, snap) {
                final count =
                    snap.hasData ? snap.data!.docs.length : 0;
                return _SummaryCard(
                  title: 'Logs This Week',
                  value: '$count',
                  subtitle: count >= 7
                      ? 'Full week logged ✓'
                      : 'days logged this week',
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<SessionModel?>(
              future: _fetchNextSession(childId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return _SummaryCard(
                    title: 'Upcoming Session',
                    value: '—',
                    subtitle: snap.connectionState == ConnectionState.waiting
                        ? 'Loading...'
                        : 'No sessions scheduled',
                  );
                }
                final s = snap.data!;
                final dateStr = '${_weekday(s.scheduledAt)} ${s.scheduledAt.day} ${_month(s.scheduledAt)}';
                final timeStr = _formatTime(s.scheduledAt);
                return _SummaryCard(
                  title: 'Upcoming Session',
                  value: dateStr,
                  subtitle: timeStr,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(String uid, String childId) {
    final db = FirebaseFirestore.instance;
    final base = db.collection('parents').doc(uid).collection('children').doc(childId);
    final dateFormat = DateFormat('EEE d MMM');


    // Stream that merges the 3 subcollections and re-emits on any change
    final summariesStream = base.collection('dailySummaries')
        .orderBy('createdAt', descending: true).limit(3).snapshots();
    final incidentsStream = base.collection('incidents')
        .orderBy('createdAt', descending: true).limit(3).snapshots();
    final momentsStream = base.collection('positiveMoments')
        .orderBy('createdAt', descending: true).limit(3).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: summariesStream,
      builder: (context, summarySnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: incidentsStream,
          builder: (context, incidentSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: momentsStream,
              builder: (context, momentSnap) {
                final loading = !summarySnap.hasData &&
                    !incidentSnap.hasData && !momentSnap.hasData;
                final results = <Map<String, dynamic>>[];

                for (final doc in summarySnap.data?.docs ?? []) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final mood = data['moodRating'] as int?;
                  final sleep = data['sleepRating'] as int?;
                  final breakfast = data['breakfastEaten'] as bool? ?? false;
                  final lunch = data['lunchEaten'] as bool? ?? false;
                  final dinner = data['dinnerEaten'] as bool? ?? false;
                  final mealsText = [if (breakfast) 'B', if (lunch) 'L', if (dinner) 'D'].join('+');
                  final detail = [
                    if (sleep != null) 'Sleep $sleep/5',
                    if (mood != null) 'Mood $mood/5',
                    mealsText.isNotEmpty ? 'Meals: $mealsText' : 'Meals skipped',
                  ].join(' · ');
                  results.add({
                    'date': dateFormat.format(createdAt),
                    'type': 'Daily Summary',
                    'detail': detail,
                    'isIncident': false,
                    'sortDate': createdAt,
                  });
                }

                for (final doc in incidentSnap.data?.docs ?? []) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final severity = data['behaviorSeverity'] as int?;
                  final triggers = (data['antecedentTriggers'] as List<dynamic>?)?.cast<String>() ?? [];
                  final detail = [
                    if (triggers.isNotEmpty) 'Trigger: ${triggers.first}',
                    if (severity != null) 'Severity $severity/5',
                  ].join(' · ');
                  results.add({
                    'date': dateFormat.format(createdAt),
                    'type': 'Behavioral Incident',
                    'detail': detail.isNotEmpty ? detail : 'Incident logged',
                    'isIncident': true,
                    'sortDate': createdAt,
                  });
                }

                for (final doc in momentSnap.data?.docs ?? []) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final rating = data['positiveBehaviorRating'] as int?;
                  final types = (data['behaviorTypes'] as List<dynamic>?)?.cast<String>() ?? [];
                  final detail = [
                    if (types.isNotEmpty) types.first,
                    if (rating != null) 'Rating $rating/5',
                  ].join(' · ');
                  results.add({
                    'date': dateFormat.format(createdAt),
                    'type': 'Positive Moment',
                    'detail': detail.isNotEmpty ? detail : 'Positive moment logged',
                    'isIncident': false,
                    'sortDate': createdAt,
                  });
                }

                results.sort((a, b) => (b['sortDate'] as DateTime).compareTo(a['sortDate'] as DateTime));
                final items = results.take(3).toList();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Activity',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (loading)
                        const Center(child: CircularProgressIndicator())
                      else if (items.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12)),
                          child: const Text(
                              'No activity yet. Start logging to see your activity here.',
                              style: TextStyle(color: Colors.black45, fontSize: 14),
                              textAlign: TextAlign.center),
                        )
                      else
                        ...items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
                            child: _ActivityCard(
                              date: item['date'] as String,
                              type: item['type'] as String,
                              detail: item['detail'] as String,
                              isIncident: item['isIncident'] as bool,
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, String childName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          _ActionButton(
            label: "LOG TODAY'S SUMMARY",
            icon: Icons.edit_note_rounded,
            enabled: true,
            onTap: () {
              final id = _selectedChildId;
              if (id == null || id.isEmpty) return;
              final parentId =
                  FirebaseAuth.instance.currentUser?.uid ?? '';
              context.push(Routes.dailySummary, extra: {
                'parentId': parentId,
                'childId': id,
                'childName': childName
              });
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'LOG AN INCIDENT',
            icon: Icons.warning_amber_rounded,
            enabled: true,
            onTap: () {
              final id = _selectedChildId;
              if (id == null || id.isEmpty) return;
              showLogTypeSheet(context, id, childName);
            },
            secondary: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard(
      {required this.title,
      required this.value,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A00))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final bool secondary;

  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.enabled,
      required this.onTap,
      this.secondary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: enabled
              ? (secondary ? Colors.white : const Color(0xFFFF8A00))
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: enabled
                  ? (secondary
                      ? const Color(0xFFFF8A00)
                      : Colors.transparent)
                  : Colors.grey.shade300),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: enabled
                    ? (secondary
                        ? const Color(0xFFFF8A00)
                        : Colors.white)
                    : Colors.grey,
                size: 24),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? (secondary
                            ? const Color(0xFFFF8A00)
                            : Colors.white)
                        : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String date;
  final String type;
  final String detail;
  final bool isIncident;

  const _ActivityCard(
      {required this.date,
      required this.type,
      required this.detail,
      required this.isIncident});

  @override
  Widget build(BuildContext context) {
    final isPositive = type == 'Positive Moment';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isIncident
                ? Icons.warning_amber_rounded
                : isPositive
                    ? Icons.star_rounded
                    : Icons.check_circle_outline,
            color: isIncident
                ? Colors.red
                : isPositive
                    ? const Color(0xFFFF8A00)
                    : const Color(0xFF2D9D78),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log History Tab
// ─────────────────────────────────────────────────────────────────────────────

class _LogHistoryTab extends StatelessWidget {
  const _LogHistoryTab();

  @override
  Widget build(BuildContext context) {
    return LogHistoryScreen(childId: '');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder Tab
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Coming soon',
          style: TextStyle(color: Colors.black45, fontSize: 16)),
    );
  }
}