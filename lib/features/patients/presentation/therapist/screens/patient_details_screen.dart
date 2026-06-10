import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/child_model.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../data/patient_repository.dart';
import 'patient_details_screen.dart';
import 'log_review_screen.dart';

// ─── Args ─────────────────────────────────────────────────────

class PatientDetailArgs {
  final ChildModel patient;
  final String therapistId;
  final String parentName;
  final bool isDeleted;

  const PatientDetailArgs({
    required this.patient,
    required this.therapistId,
    this.parentName = '',
    this.isDeleted = false,
  });
}

// ─── Screen ───────────────────────────────────────────────────

class PatientDetailsScreen extends StatefulWidget {
  final PatientDetailArgs args;

  const PatientDetailsScreen({super.key, required this.args});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  bool _removing = false;
  Map<String, dynamic>? _parentData;
  String _parentName = '';
  List<Map<String, dynamic>> _recentLogs = [];
  bool _loadingLogs = true;

  @override
  void initState() {
    super.initState();
    // Use pre-passed parent name immediately (no flicker)
    _parentName = widget.args.parentName;
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Skip all Firestore queries for deleted patients — paths no longer valid
    if (widget.args.isDeleted) {
      setState(() => _loadingLogs = false);
      return;
    }
    try {
      final therapistId = widget.args.therapistId;
      final patient    = widget.args.patient;

      // ── Parent name: 3-tier lookup ──────────────────────────────────────────

      // 1. patients doc (has parentName for links accepted after the latest update)
      try {
        final patientDoc = await FirebaseFirestore.instance
            .collection('therapists')
            .doc(therapistId)
            .collection('patients')
            .doc(patient.childId)
            .get();
        _parentName = patientDoc.data()?['parentName'] as String? ?? '';
      } catch (_) {}

      // 2. linkRequests — filter by therapistEmail (new docs) or therapistId (old docs)
      if (_parentName.isEmpty) {
        try {
          final therapistEmail =
              FirebaseAuth.instance.currentUser?.email ?? '';
          final linkSnap = await FirebaseFirestore.instance
              .collection('linkRequests')
              .where('childId', isEqualTo: patient.childId)
              .where('therapistEmail', isEqualTo: therapistEmail)
              .limit(1)
              .get();
          if (linkSnap.docs.isNotEmpty) {
            _parentName =
                linkSnap.docs.first.data()['parentName'] as String? ?? '';
          }
        } catch (_) {}
      }

      // 2b. Fallback: old linkRequests used therapistId field instead of therapistEmail
      if (_parentName.isEmpty) {
        try {
          final linkSnap = await FirebaseFirestore.instance
              .collection('linkRequests')
              .where('childId', isEqualTo: patient.childId)
              .where('therapistId', isEqualTo: therapistId)
              .limit(1)
              .get();
          if (linkSnap.docs.isNotEmpty) {
            _parentName =
                linkSnap.docs.first.data()['parentName'] as String? ?? '';
          }
        } catch (_) {}
      }

      // 3. Read parent doc directly — therapists are allowed per security rules
      if (_parentName.isEmpty && patient.parentId.isNotEmpty) {
        try {
          final parentDoc = await FirebaseFirestore.instance
              .collection('parents')
              .doc(patient.parentId)
              .get();
          _parentData = parentDoc.data();
          _parentName = _parentData?['name'] as String? ?? '';
        } catch (_) {}
      }

      // Update UI as soon as the name is known
      if (mounted && _parentName.isNotEmpty) setState(() {});

      // Fetch recent logs — daily summaries
      final summaries = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.args.patient.parentId)
          .collection('children')
          .doc(widget.args.patient.childId)
          .collection('dailySummaries')
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      final logs = summaries.docs.map((doc) {
        final data = doc.data();
        return {
          'type': 'summary',
          'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'moodRating': data['moodRating'] ?? 0,
          'sleepRating': data['sleepRating'] ?? 0,
        };
      }).toList();

      // Fetch incidents
      final incidents = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.args.patient.parentId)
          .collection('children')
          .doc(widget.args.patient.childId)
          .collection('incidents')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in incidents.docs) {
        final data = doc.data();
        logs.add({
          'type': 'incident',
          'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'severity': data['behaviorSeverity'] ?? 0,
          'behaviorTypes': data['behaviorTypes'] ?? [],
        });
      }

      logs.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      setState(() {
        _recentLogs = logs.take(5).toList();
        _loadingLogs = false;
      });
    } catch (_) {
      setState(() {
        _loadingLogs = false;
      });
    }
  }

  Future<void> _removePatient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Patient'),
        content: Text(
          'Are you sure you want to remove ${widget.args.patient.name}? They will no longer be linked to you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _removing = true);

    // Pop first when patient is deleted — avoids Firestore stream assertion errors
    // caused by security re-evaluation while active listeners are watching deleted paths.
    if (widget.args.isDeleted && mounted) {
      context.pop();
      PatientRepository().removePatient(
        therapistId: widget.args.therapistId,
        parentId: widget.args.patient.parentId,
        childId: widget.args.patient.childId,
      ).ignore();
      return;
    }

    try {
      await PatientRepository().removePatient(
        therapistId: widget.args.therapistId,
        parentId: widget.args.patient.parentId,
        childId: widget.args.patient.childId,
      );
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Patient removed successfully.');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to remove patient.');
        setState(() => _removing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.args.patient;
    final parentName = _parentName.isNotEmpty ? _parentName : 'Unknown Parent';

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textMain),
          onPressed: () => context.pop(),
        ),
        title: Text(patient.name, style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.textMain),
            onSelected: (value) {
              if (value == 'remove') _removePatient();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    const Icon(Icons.person_remove_outlined, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text('Remove Patient', style: AppTextStyles.body.copyWith(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Deleted banner ────────────────────────────────────────────
            if (widget.args.isDeleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error20,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Text('Profile Deleted',
                            style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The parent has deleted this child\'s profile. '
                      'You can remove them from your patient list.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _removing ? null : _removePatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Remove from My Patients',
                            style: AppTextStyles.body
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Patient info card ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDefault,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderInactive),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(name: patient.name, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('DOB: ${DateFormat('d MMM yyyy').format(patient.dateOfBirth)}', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
                          ],
                        ),
                      ),
                      _SeverityBadge(level: patient.severityLevel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.dividerLight),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Parent', value: parentName),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── AI Insights ───────────────────────────────────────────────
            _SectionTitle('AI Insights'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary20,
                borderRadius: BorderRadius.circular(14),
              ),
              child: widget.args.isDeleted
                  ? Text(
                      'AI insights unavailable — child profile has been deleted.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                    )
                  : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('parents')
                    .doc(patient.parentId)
                    .collection('children')
                    .doc(patient.childId)
                    .collection('aiInsights')
                    .doc('current')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text(
                      'No AI insights available yet. Insights unlock after 7 days of parent logging.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                    );
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final isUnlocked = data['isUnlocked'] ?? false;
                  if (!isUnlocked) {
                    final daysLogged = data['daysLogged'] ?? 0;
                    return Text(
                      '$daysLogged / 7 days logged. ${7 - daysLogged} more days to unlock AI insights.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                    );
                  }
                  final insights = data['weeklyInsights'] as Map<String, dynamic>?;
                  final summary = insights?['summary'] as String? ?? '';
                  final direction = insights?['progressDirection'] as String? ?? 'stable';
                  final directionLabel = direction == 'improving' ? '↑ Improving' : direction == 'needs_attention' ? '↓ Needs attention' : '→ Stable';
                  final directionColor = direction == 'improving' ? AppColors.success : direction == 'needs_attention' ? AppColors.error : AppColors.warning;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.secondary, size: 14),
                          const SizedBox(width: 4),
                          Text('Weekly AI Summary', style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: directionColor, borderRadius: BorderRadius.circular(20)),
                            child: Text(directionLabel, style: AppTextStyles.tag.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(summary, style: AppTextStyles.caption, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Recent Logs ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle('Recent Logs'),
                TextButton(
                  onPressed: () => context.push(Routes.logReview, extra: LogReviewArgs(
                  parentId: patient.parentId,
                  childId: patient.childId,
                  childName: patient.name,
                  initialTab: 0,
                )),
                  child: Text('View All', style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingLogs)
              const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
            else if (_recentLogs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
                child: Text('No logs yet.', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle), textAlign: TextAlign.center),
              )
            else
              ...(_recentLogs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LogRow(
                log: log,
                parentId: patient.parentId,
                childId: patient.childId,
                childName: patient.name,
              ),
              ))),
            const SizedBox(height: 20),

            // ── Upcoming Sessions (placeholder) ───────────────────────────
            _SectionTitle('Upcoming Sessions'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
              child: Text('Session booking coming in Sprint 3.', style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 32),

            // ── Remove button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _removing ? null : _removePatient,
                icon: _removing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                    : const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.error),
                label: Text('Remove Patient', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildTabBar(context),
    );
  }

  Widget _buildTabBar(BuildContext context) {
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
              _TabItem(icon: Icons.home_outlined, label: 'Home', onTap: () => context.go(Routes.therapistHome)),
              _TabItem(icon: Icons.people_outline, label: 'Patients', active: true, onTap: () => context.go(Routes.therapistPatients)),
              _TabItem(icon: Icons.calendar_month_outlined, label: 'Sessions', onTap: () => context.go(Routes.therapistSessions),),
              _TabItem(icon: Icons.bar_chart_outlined, label: 'Reports', onTap: () => context.go(Routes.therapistReports),),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable widgets ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label  ', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textSubtle))),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, required this.size});

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary20),
      alignment: Alignment.center,
      child: Text(_initials, style: TextStyle(fontSize: size * 0.33, fontWeight: FontWeight.w700, color: AppColors.secondary)),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final int level;
  const _SeverityBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = level == 1 ? AppColors.secondary : level == 2 ? AppColors.secondaryOrange : AppColors.error;
    final bg = level == 1 ? AppColors.secondary20 : level == 2 ? AppColors.secondaryOrange20 : AppColors.error20;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('ASD – LEVEL $level', style: AppTextStyles.tag.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _LogRow extends StatelessWidget {
  final Map<String, dynamic> log;
  final String parentId;
  final String childId;
  final String childName;

  const _LogRow({
    required this.log,
    required this.parentId,
    required this.childId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    final date = log['date'] as DateTime;
    final dateStr = DateFormat('EEE d MMM').format(date);
    final isIncident = log['type'] == 'incident';
    final color = isIncident ? AppColors.accentRed : AppColors.secondary;
    final label = isIncident ? 'INCIDENT' : 'SUMMARY';

    String detail = '';
    if (isIncident) {
      final types = (log['behaviorTypes'] as List<dynamic>?)?.cast<String>() ?? [];
      final severity = log['severity'] as int? ?? 0;
      detail = '${types.isNotEmpty ? types.first : 'Incident'} · Severity $severity/5';
    } else {
      final mood = log['moodRating'] as int? ?? 0;
      final sleep = log['sleepRating'] as int? ?? 0;
      final moodLabels = ['', 'Bad', 'Poor', 'Average', 'Good', 'Excellent'];
      final sleepLabels = ['', 'Bad', 'Poor', 'Average', 'Good', 'Excellent'];
      detail = 'Sleep: ${sleepLabels.elementAtOrNull(sleep) ?? sleep} · Mood: ${moodLabels.elementAtOrNull(mood) ?? mood}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.tag.copyWith(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
              ],
            ),
          ),
          Text(dateStr, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push(Routes.logReview, extra: LogReviewArgs(
              parentId: parentId,
              childId: childId,
              childName: childName,
              initialTab: log['type'] == 'incident' ? 1 : 0,
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
              child: Text('Review', style: AppTextStyles.tag.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _TabItem({required this.icon, required this.label, this.active = false, this.onTap});

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