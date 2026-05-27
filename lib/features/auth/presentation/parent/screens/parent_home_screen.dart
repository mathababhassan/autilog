import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../features/incident_log/presentation/screens/logs_list_screen.dart';
import '../../../../../features/incident_log/presentation/widgets/log_type_sheet.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: switch (_currentIndex) {
        0 => const _DashboardTab(),
        1 => const LogsListTab(),
        _ => const _PlaceholderTab(),
      },
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String? _selectedChildId;

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

            // Auto-select first child if none selected yet
            if (hasChild && _selectedChildId == null) {
              _selectedChildId = children.first.id;
            }

            // Selected child data
            final selectedChildDoc = hasChild
                ? children.where((c) => c.id == _selectedChildId).firstOrNull
                : null;
            final selectedChildData =
                selectedChildDoc?.data() as Map<String, dynamic>?;
            final selectedChildName =
                selectedChildData?['name'] as String? ?? '';

            return CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildAppBar(context, parentName)),

                // ── Child Switcher (only if more than 1 child) ─────────
                if (children.length > 1)
                  SliverToBoxAdapter(child: _buildChildSwitcher(children)),

                // ── Content based on child state ───────────────────────
                if (!hasChild) ...[
                  SliverToBoxAdapter(child: _buildNoChildBanner(context)),
                  SliverToBoxAdapter(child: _buildEmptySummaryCards()),
                  SliverToBoxAdapter(child: _buildDisabledActions()),
                  SliverToBoxAdapter(child: _buildEmptyActivity()),
                  SliverToBoxAdapter(child: _buildEmptyInsights()),
                ] else ...[
                  SliverToBoxAdapter(child: _buildSummaryCards()),
                  SliverToBoxAdapter(
                    child: _buildActions(context, selectedChildName),
                  ),
                  SliverToBoxAdapter(child: _buildRecentActivity()),
                  SliverToBoxAdapter(child: _buildInsights(selectedChildName)),
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

  // ── App Bar ──────────────────────────────────────────────────────────────

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
              const Text(
                'AutiLog',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(Routes.parentProfile),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$greeting, $parentName 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Child Switcher Dropdown ──────────────────────────────────────────────

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
              if (id != null) setState(() => _selectedChildId = id);
            },
          ),
        ),
      ),
    );
  }

  // ── No child banner ──────────────────────────────────────────────────────

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
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF8A00),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'No child profile yet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
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
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ADD CHILD PROFILE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptySummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Logs This Week',
              value: '— —',
              subtitle: 'Add a child to start',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Upcoming Session',
              value: '— —',
              subtitle: 'Add a child to start',
            ),
          ),
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
            secondary: true,
          ),
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
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: const Text(
              'No activity yet. Add a child profile and start logging to see your activity here.',
              style: TextStyle(color: Colors.black45, fontSize: 14),
              textAlign: TextAlign.center,
            ),
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
          const Text(
            'AI Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: const Text(
              'Insights will appear after 7 days of logging. Add a child profile to begin.',
              style: TextStyle(color: Colors.black45, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Has-child state ──────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Logs This Week',
              value: '4 / 7',
              subtitle: 'days logged ✓',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Upcoming Session',
              value: 'Thu 22 Apr',
              subtitle: '2:00 PM',
            ),
          ),
        ],
      ),
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

    final parentId = FirebaseAuth.instance.currentUser?.uid ?? '';

    context.push(
      Routes.dailySummary,
      extra: {
        'parentId': parentId,
        'childId': id,
        'childName': childName,
      },
    );
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

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            date: 'Mon 19 Apr',
            type: 'Daily Summary',
            detail: 'Sleep 4/5 · Mood 3/5 · Meals all eaten',
            isIncident: false,
          ),
          const SizedBox(height: 10),
          _ActivityCard(
            date: 'Mon 19 Apr',
            type: 'Behavioral Incident',
            detail: 'Trigger: Loud environment · Severity 4/5',
            isIncident: true,
          ),
          const SizedBox(height: 10),
          _ActivityCard(
            date: 'Sun 18 Apr',
            type: 'Daily Summary',
            detail: 'Sleep 3/5 · Mood 2/5 · Skipped dinner',
            isIncident: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(String childName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF8A00).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$childName tends to have better days when sleeping more than 7 hours. Try keeping bedtime consistent this week.',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See all →',
                      style: TextStyle(
                        color: Color(0xFFFF8A00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8A00),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
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

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: enabled
              ? (secondary ? Colors.white : const Color(0xFFFF8A00))
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? (secondary ? const Color(0xFFFF8A00) : Colors.transparent)
                : Colors.grey.shade300,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled
                  ? (secondary ? const Color(0xFFFF8A00) : Colors.white)
                  : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? (secondary ? const Color(0xFFFF8A00) : Colors.white)
                    : Colors.grey,
              ),
            ),
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

  const _ActivityCard({
    required this.date,
    required this.type,
    required this.detail,
    required this.isIncident,
  });

  @override
  Widget build(BuildContext context) {
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
                : Icons.check_circle_outline,
            color: isIncident ? Colors.red : const Color(0xFFFF8A00),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      child: Text(
        'Coming soon',
        style: TextStyle(color: Colors.black45, fontSize: 16),
      ),
    );
  }
}
