// PLACEHOLDER: built to test the incident logging feature end-to-end.
// Only incident logs are shown. Positive Moment and Daily Summary are not yet implemented.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/child_model.dart';
import '../../../../shared/models/incident_model.dart';
import 'incident_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab entry point
// ─────────────────────────────────────────────────────────────────────────────

class LogsListTab extends StatefulWidget {
  const LogsListTab({super.key});

  @override
  State<LogsListTab> createState() => _LogsListTabState();
}

class _LogsListTabState extends State<LogsListTab> {
  String? _selectedChildId;

  @override
    Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // If not logged in, show login required message
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view incidents'),
        ),
      );
    }
    
    final uid = user.uid;

    return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('parents')
      .doc(uid)
      .collection('children')
      .snapshots(),
  builder: (context, childSnap) {
    // Show loading spinner while waiting
    if (childSnap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Show error message if something went wrong
    if (childSnap.hasError) {
      return Center(
        child: Text('Error loading children: ${childSnap.error}'),
      );
    }
    
    final childDocs = childSnap.data?.docs ?? <QueryDocumentSnapshot>[];

        if (childDocs.isNotEmpty && _selectedChildId == null) {
  _selectedChildId = childDocs.first.id;
}

// Fix: If selected child no longer exists, pick the first available child
if (_selectedChildId != null && 
    !childDocs.any((doc) => doc.id == _selectedChildId)) {
  _selectedChildId = childDocs.isNotEmpty ? childDocs.first.id : null;
}

final childModels = <String, ChildModel>{
  for (final doc in childDocs) doc.id: _toChildModel(doc, uid),
};

final selectedChild =
    _selectedChildId != null ? childModels[_selectedChildId] : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(childName: selectedChild?.name),
            if (childDocs.length > 1)
              _ChildSwitcher(
                children: childDocs,
                selectedId: _selectedChildId,
                onChanged: (id) => setState(() => _selectedChildId = id),
              ),
            Expanded(
              child: selectedChild == null
                  ? const _EmptyNoChild()
                  : _IncidentListView(childModel: selectedChild),
            ),
          ],
        );
      },
    );
  }

  ChildModel _toChildModel(QueryDocumentSnapshot doc, String uid) {
    final data = doc.data() as Map<String, dynamic>;
    final parentId =
        (data['parentId'] as String?)?.isNotEmpty == true
            ? data['parentId'] as String
            : uid;
    return ChildModel.fromMap({...data, 'parentId': parentId}, doc.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — mirrors incident_form_screen _TopBar style (white, bottom border)
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String? childName;

  const _TopBar({this.childName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.lg,
          AppSpacing.screenMargin,
          AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDefault,
          border: Border(
            bottom: BorderSide(color: AppColors.borderInactive),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('My Logs', style: AppTextStyles.heading1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error20,
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    'INCIDENTS',
                    style: AppTextStyles.tag.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              childName != null
                  ? 'Logs saved for $childName'
                  : 'All incident logs',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Child switcher — shown only when 2+ children exist
// ─────────────────────────────────────────────────────────────────────────────

class _ChildSwitcher extends StatelessWidget {
  final List<QueryDocumentSnapshot> children;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const _ChildSwitcher({
    required this.children,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.lg,
        AppSpacing.screenMargin,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primary,
            ),
            items: children.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? 'Child';
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary20,
                      child: Icon(
                        Icons.child_care,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (id) {
              if (id != null) onChanged(id);
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incident list — streams incidents for the selected child
// ─────────────────────────────────────────────────────────────────────────────

class _IncidentListView extends StatelessWidget {
  final ChildModel childModel;

  const _IncidentListView({required this.childModel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parents')
          .doc(childModel.parentId)
          .collection('children')
          .doc(childModel.childId)
          .collection('incidents')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snap.data?.docs ?? <QueryDocumentSnapshot>[];

        if (docs.isEmpty) return const _EmptyLogs();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.lg,
            AppSpacing.screenMargin,
            AppSpacing.xl4,
          ),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) {
            final incident = IncidentModel.fromMap(
              docs[i].data() as Map<String, dynamic>,
              docs[i].id,
            );
            return _IncidentCard(
              incident: incident,
              onTap: () => context.push(
                Routes.incidentDetail,
                extra: IncidentDetailArgs(
                  incidentId: incident.id,
                  child: childModel,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incident card
// ─────────────────────────────────────────────────────────────────────────────

class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const _IncidentCard({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM yyyy').format(incident.date);
    final time = incident.time.format(context);
    final primaryBehavior = incident.behaviorTypes.isNotEmpty
        ? incident.behaviorTypes.first
        : 'Unspecified';
    final hasFeedback = incident.therapistFeedback != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderInactive),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type chip + date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error20,
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    'INCIDENT',
                    style: AppTextStyles.tag.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Primary behavior type
            Text(
              primaryBehavior,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Time + severity
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 14,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(width: 4),
                Text(
                  'Severity ${incident.behaviorSeverity}/5',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
            if (hasFeedback) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Therapist feedback received',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNoChild extends StatelessWidget {
  const _EmptyNoChild();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.child_care,
              size: 56,
              color: AppColors.borderInactive,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No child profile yet',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add a child profile from the Home tab to start logging.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPlaceholder,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 56,
            color: AppColors.borderInactive,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No logs yet',
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Incidents you log will appear here.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }
}
