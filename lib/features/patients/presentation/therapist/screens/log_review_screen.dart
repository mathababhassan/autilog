import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/theme.dart';

// ─── Args ─────────────────────────────────────────────────────

class LogReviewArgs {
  final String parentId;
  final String childId;
  final String childName;
  final int initialTab; // 0 = Daily Summaries, 1 = Incident Logs

  const LogReviewArgs({
    required this.parentId,
    required this.childId,
    required this.childName,
    this.initialTab = 0,
  });
}

// ─── Screen ───────────────────────────────────────────────────

class LogReviewScreen extends StatefulWidget {
  final LogReviewArgs args;

  const LogReviewScreen({super.key, required this.args});

  @override
  State<LogReviewScreen> createState() => _LogReviewScreenState();
}

class _LogReviewScreenState extends State<LogReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _outerTabController;

  @override
  void initState() {
    super.initState();
    _outerTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.args.initialTab,
    );
  }

  @override
  void dispose() {
    _outerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textMain),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Review',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              widget.args.childName,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _OuterTab(
                  label: 'Daily Summaries',
                  active: _outerTabController.index == 0,
                  onTap: () => setState(() => _outerTabController.animateTo(0)),
                ),
                const SizedBox(width: 8),
                _OuterTab(
                  label: 'Incident Logs',
                  active: _outerTabController.index == 1,
                  onTap: () => setState(() => _outerTabController.animateTo(1)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _outerTabController,
        children: [
          _DailySummariesTab(
            parentId: widget.args.parentId,
            childId: widget.args.childId,
            childName: widget.args.childName,
          ),
          _IncidentLogsTab(
            parentId: widget.args.parentId,
            childId: widget.args.childId,
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

// ─── Daily Summaries Tab (with inner tabs) ────────────────────

class _DailySummariesTab extends StatefulWidget {
  final String parentId;
  final String childId;
  final String childName;

  const _DailySummariesTab({
    required this.parentId,
    required this.childId,
    required this.childName,
  });

  @override
  State<_DailySummariesTab> createState() => _DailySummariesTabState();
}

class _DailySummariesTabState extends State<_DailySummariesTab> {
  int _innerTab = 0; // 0 = Questions, 1 = Logs

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inner tab row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _InnerTab(
                label: 'Questions',
                active: _innerTab == 0,
                onTap: () => setState(() => _innerTab = 0),
              ),
              const SizedBox(width: 20),
              _InnerTab(
                label: 'Logs',
                active: _innerTab == 1,
                onTap: () => setState(() => _innerTab = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: AppColors.dividerLight),
        Expanded(
          child: _innerTab == 0
              ? _QuestionsView(
                  parentId: widget.parentId,
                  childId: widget.childId,
                  childName: widget.childName,
                )
              : _DailySummaryLogsView(
                  parentId: widget.parentId,
                  childId: widget.childId,
                ),
        ),
      ],
    );
  }
}

// ─── Questions View ───────────────────────────────────────────

class _QuestionsView extends StatefulWidget {
  final String parentId;
  final String childId;
  final String childName;

  const _QuestionsView({
    required this.parentId,
    required this.childId,
    required this.childName,
  });

  @override
  State<_QuestionsView> createState() => _QuestionsViewState();
}

class _QuestionsViewState extends State<_QuestionsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              // Search
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSubtle, size: 20),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Inactive'].map((f) {
                    final active = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surfaceDefault,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? AppColors.primary : AppColors.borderInactive,
                            ),
                          ),
                          child: Text(
                            f,
                            style: AppTextStyles.caption.copyWith(
                              color: active ? AppColors.textWhite : AppColors.textMain,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('parents')
                .doc(widget.parentId)
                .collection('children')
                .doc(widget.childId)
                .collection('trackingQuestions')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final docs = snapshot.data?.docs ?? [];

              var filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final text = (data['questionText'] as String? ?? '').toLowerCase();
                final status = data['status'] as String? ?? 'active';
                final matchesSearch = _searchQuery.isEmpty || text.contains(_searchQuery);
                final matchesFilter = _filter == 'All' ||
                    (_filter == 'Active' && status == 'active') ||
                    (_filter == 'Inactive' && status == 'inactive');
                return matchesSearch && matchesFilter;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help_outline, size: 48, color: AppColors.textSubtle),
                      const SizedBox(height: 12),
                      Text(
                        'No tracking questions yet',
                        style: AppTextStyles.subtitle.copyWith(color: AppColors.textSubtle),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add questions to track specific behaviors\nin ${widget.childName}\'s daily summary.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final doc = filtered[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final questionText = data['questionText'] as String? ?? '';
                  final answerType = data['answerType'] as String? ?? '';
                  final status = data['status'] as String? ?? 'active';
                  final isActive = status == 'active';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDefault,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: isActive ? AppColors.secondary : AppColors.borderInactive,
                          width: 4,
                        ),
                        top: BorderSide(color: AppColors.borderInactive),
                        right: BorderSide(color: AppColors.borderInactive),
                        bottom: BorderSide(color: AppColors.borderInactive),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                questionText,
                                style: AppTextStyles.body.copyWith(
                                  color: isActive ? AppColors.textMain : AppColors.textDisabled,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFE6F9E8)
                                    : AppColors.inputFill,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: isActive ? AppColors.success : AppColors.textSubtle,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: AppTextStyles.tag.copyWith(
                                      color: isActive ? AppColors.success : AppColors.textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Answer type: $answerType',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isActive)
                              TextButton(
                                onPressed: () {
                                  // TODO: wire T-20 Edit Question popup
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Edit',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('parents')
                                      .doc(widget.parentId)
                                      .collection('children')
                                      .doc(widget.childId)
                                      .collection('trackingQuestions')
                                      .doc(doc.id)
                                      .update({'status': 'active'});
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Reactivate',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                // TODO: wire T-21 Delete confirmation popup
                              },
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Delete',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Add Question button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: wire T-19 Add Question popup
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Text(
                '+ ADD QUESTION',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Daily Summary Logs View ──────────────────────────────────

class _DailySummaryLogsView extends StatefulWidget {
  final String parentId;
  final String childId;

  const _DailySummaryLogsView({
    required this.parentId,
    required this.childId,
  });

  @override
  State<_DailySummaryLogsView> createState() => _DailySummaryLogsViewState();
}

class _DailySummaryLogsViewState extends State<_DailySummaryLogsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'All';
  final Set<String> _expandedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSubtle, size: 20),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'This Week', 'Last 7 Days', 'Has Comment'].map((f) {
                    final active = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surfaceDefault,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? AppColors.primary : AppColors.borderInactive,
                            ),
                          ),
                          child: Text(
                            f,
                            style: AppTextStyles.caption.copyWith(
                              color: active ? AppColors.textWhite : AppColors.textMain,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('parents')
                .doc(widget.parentId)
                .collection('children')
                .doc(widget.childId)
                .collection('dailySummaries')
                .orderBy('date', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              var docs = snapshot.data?.docs ?? [];

              // Apply filters
              final now = DateTime.now();
              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

                if (_filter == 'This Week') {
                  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                  if (date.isBefore(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day))) return false;
                }
                if (_filter == 'Last 7 Days') {
                  if (date.isBefore(now.subtract(const Duration(days: 7)))) return false;
                }
                return true;
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No daily summaries found.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.dividerLight),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final dateStr = DateFormat('EEE d MMM').format(date);
                  final isExpanded = _expandedIds.contains(doc.id);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() {
                          if (isExpanded) {
                            _expandedIds.remove(doc.id);
                          } else {
                            _expandedIds.add(doc.id);
                          }
                        }),
                        child: Row(
                          children: [
                            Icon(
                              isExpanded ? Icons.expand_more : Icons.chevron_right,
                              color: AppColors.textSubtle,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$dateStr — Daily Summary',
                              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 10),
                        _DailySummaryDataBlock(data: data),
                        const SizedBox(height: 10),
                        _CommentsSection(
                          parentId: widget.parentId,
                          childId: widget.childId,
                          logCollection: 'dailySummaries',
                          logId: doc.id,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Incident Logs Tab ────────────────────────────────────────

class _IncidentLogsTab extends StatefulWidget {
  final String parentId;
  final String childId;

  const _IncidentLogsTab({
    required this.parentId,
    required this.childId,
  });

  @override
  State<_IncidentLogsTab> createState() => _IncidentLogsTabState();
}

class _IncidentLogsTabState extends State<_IncidentLogsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'All';
  final Set<String> _expandedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search incidents...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSubtle, size: 20),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Behavioral', 'Positive', 'High Severity'].map((f) {
                    final active = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surfaceDefault,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? AppColors.primary : AppColors.borderInactive,
                            ),
                          ),
                          child: Text(
                            f,
                            style: AppTextStyles.caption.copyWith(
                              color: active ? AppColors.textWhite : AppColors.textMain,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('parents')
                .doc(widget.parentId)
                .collection('children')
                .doc(widget.childId)
                .collection('incidents')
                .orderBy('date', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              var docs = snapshot.data?.docs ?? [];

              // Apply filter
              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = data['type'] as String? ?? '';
                final severity = data['behaviorSeverity'] as int? ?? 0;

                if (_filter == 'Behavioral' && type != 'behavioral') return false;
                if (_filter == 'Positive' && type != 'positive') return false;
                if (_filter == 'High Severity' && severity < 4) return false;
                return true;
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No incident logs found.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.dividerLight),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final dateStr = DateFormat('EEE d MMM').format(date);
                  final type = data['type'] as String? ?? 'behavioral';
                  final isPositive = type == 'positiveMoment' || type == 'positive';
                  final isExpanded = _expandedIds.contains(doc.id);

                  final accentColor = isPositive ? AppColors.success : AppColors.secondaryOrange;
                  final label = isPositive ? 'Positive Moment ★' : 'Behavioral Incident ⚠';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() {
                          if (isExpanded) {
                            _expandedIds.remove(doc.id);
                          } else {
                            _expandedIds.add(doc.id);
                          }
                        }),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.expand_more : Icons.chevron_right,
                              color: AppColors.textSubtle,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$dateStr — $label',
                                style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 10),
                        _IncidentDataBlock(data: data, isPositive: isPositive),
                        const SizedBox(height: 10),
                        _CommentsSection(
                          parentId: widget.parentId,
                          childId: widget.childId,
                          logCollection: 'incidents',
                          logId: doc.id,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Daily Summary Data Block ─────────────────────────────────

class _DailySummaryDataBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DailySummaryDataBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final sleepRating = data['sleepRating'] ?? 0;
    final moodRating = data['moodRating'] ?? 0;
    final mealLabels = ['', 'Bad', 'Poor', 'Average', 'Good', 'Excellent'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _DataRow(label: 'Sleep', value: '$sleepRating/5'),
          _DataRow(label: 'Mood', value: '$moodRating/5'),
          if (data['breakfastEaten'] != null)
            _DataRow(label: 'Breakfast', value: (data['breakfastEaten'] as bool) ? '✓' : '✗'),
          if (data['lunchEaten'] != null)
            _DataRow(label: 'Lunch', value: (data['lunchEaten'] as bool) ? '✓' : '✗'),
          if (data['dinnerEaten'] != null)
            _DataRow(label: 'Dinner', value: (data['dinnerEaten'] as bool) ? '✓' : '✗'),
          if (data['routineDisrupted'] != null)
            _DataRow(label: 'Routine', value: (data['routineDisrupted'] as bool) ? 'Disrupted' : 'Normal'),
        ],
      ),
    );
  }
}

// ─── Incident Data Block ──────────────────────────────────────

class _IncidentDataBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isPositive;

  const _IncidentDataBlock({required this.data, required this.isPositive});

  String _formatTime(int? minutes) {
    if (minutes == null) return '--';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:${m.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(data['time'] as int?);
    final antecedent = data['antecedentDescription'] as String? ?? '';
    final behavior = data['behaviorDescription'] as String? ?? '';
    final consequence = data['consequenceDescription'] as String? ?? '';
    final severity = data['behaviorSeverity'] ?? data['positiveBehaviorRating'] ?? 0;
    final effectiveness = data['effectiveness'] ?? 0;
    final videoUrl = data['videoUrl'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _DataRow(label: 'Time', value: time),
              if (antecedent.isNotEmpty)
                _DataRow(label: 'A — Trigger', value: antecedent),
              if (behavior.isNotEmpty)
                _DataRow(label: 'B — Behavior', value: '$behavior · Severity $severity/5'),
              if (consequence.isNotEmpty)
                _DataRow(label: 'C — Response', value: '$consequence · Effectiveness $effectiveness/5'),
            ],
          ),
        ),
        if (videoUrl != null && videoUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary20,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, color: AppColors.secondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Attached video',
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Comments Section ─────────────────────────────────────────

class _CommentsSection extends StatelessWidget {
  final String parentId;
  final String childId;
  final String logCollection;
  final String logId;

  const _CommentsSection({
    required this.parentId,
    required this.childId,
    required this.logCollection,
    required this.logId,
  });

  @override
  Widget build(BuildContext context) {
    final therapistId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection(logCollection)
          .doc(logId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        final comments = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...comments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final text = data['text'] as String? ?? '';
              final therapistName = data['therapistName'] as String? ?? 'Dr.';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final timeStr = createdAt != null
                  ? DateFormat('d MMM hh:mm a').format(createdAt)
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDefault,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: AppColors.secondary, width: 4),
                    top: BorderSide(color: AppColors.borderInactive),
                    right: BorderSide(color: AppColors.borderInactive),
                    bottom: BorderSide(color: AppColors.borderInactive),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$therapistName — $timeStr',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(text, style: AppTextStyles.body),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: wire T-17 Edit Comment popup
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Edit',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            // TODO: wire T-18 Delete Comment popup
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Delete',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            // Add Comment button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: wire T-16 Add Comment popup
                  _showAddCommentSheet(context, parentId, childId, logCollection, logId, therapistId);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Text(
                  '+ Add Comment',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCommentSheet(
    BuildContext context,
    String parentId,
    String childId,
    String logCollection,
    String logId,
    String therapistId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddCommentSheet(
        parentId: parentId,
        childId: childId,
        logCollection: logCollection,
        logId: logId,
        therapistId: therapistId,
      ),
    );
  }
}

// ─── Add Comment Bottom Sheet (T-16) ─────────────────────────

class _AddCommentSheet extends StatefulWidget {
  final String parentId;
  final String childId;
  final String logCollection;
  final String logId;
  final String therapistId;

  const _AddCommentSheet({
    required this.parentId,
    required this.childId,
    required this.logCollection,
    required this.logId,
    required this.therapistId,
  });

  @override
  State<_AddCommentSheet> createState() => _AddCommentSheetState();
}

class _AddCommentSheetState extends State<_AddCommentSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);

    try {
      // Fetch therapist name
      final therapistSnap = await FirebaseFirestore.instance
          .collection('therapists')
          .doc(widget.therapistId)
          .get();
      final therapistName = therapistSnap.data()?['name'] as String? ?? 'Therapist';

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection(widget.logCollection)
          .doc(widget.logId)
          .collection('comments')
          .add({
        'text': text,
        'therapistId': widget.therapistId,
        'therapistName': therapistName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Comment',
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Write your clinical observation here...',
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.textSubtle),
              const SizedBox(width: 4),
              Text(
                'Parent will be notified when you submit.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'ADD COMMENT',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(color: AppColors.textSubtle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────

class _OuterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _OuterTab({required this.label, required this.active, required this.onTap});

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

class _InnerTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _InnerTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: active ? AppColors.primary : AppColors.textSubtle,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            color: active ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMain),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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
              _NavItem(icon: Icons.home_outlined, label: 'Home', onTap: () => context.go('/therapist/home')),
              _NavItem(icon: Icons.people_outline, label: 'Patients', active: true, onTap: () => context.go('/therapist/patients')),
              const _NavItem(icon: Icons.calendar_month_outlined, label: 'Sessions'),
              const _NavItem(icon: Icons.bar_chart_outlined, label: 'Reports'),
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
