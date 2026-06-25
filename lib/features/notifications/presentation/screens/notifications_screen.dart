import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../data/notification_model.dart';
import '../../data/notification_repository.dart';
import '../widgets/notification_tile.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/child_model.dart';
import '../../../incident_log/presentation/screens/incident_detail_screen.dart';
import '../../../positive_moment/presentation/screens/positive_moment_detail_screen.dart';
import '../../../patients/presentation/therapist/screens/log_review_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../patients/presentation/therapist/screens/patient_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry points — one for each role, both delegate to _NotificationsView
// ─────────────────────────────────────────────────────────────────────────────

/// Parent notifications screen (P-39).
class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _NotificationsView(isTherapist: false);
}

/// Therapist notifications screen (T-35).
class TherapistNotificationsScreen extends StatelessWidget {
  const TherapistNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _NotificationsView(isTherapist: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared view
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsView extends StatefulWidget {
  const _NotificationsView({required this.isTherapist});

  final bool isTherapist;

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  late final NotificationRepository _repo;
  String _uid = '';
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    _repo = NotificationRepository();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // ─── Firestore writes ──────────────────────────────────────────────────────

  Future<void> _markRead(String id) async {
    if (_uid.isEmpty) return;
    await _repo.markAsRead(
      uid: _uid,
      isTherapist: widget.isTherapist,
      notificationId: id,
    );
  }

  Future<void> _markAllRead() async {
    if (_uid.isEmpty || _isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    try {
      await _repo.markAllAsRead(uid: _uid, isTherapist: widget.isTherapist);
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────
  void _navigate(NotificationModel n) async {
    final childId = n.targetChildId ?? '';
    final parentId = n.targetParentId ?? '';
    final kind = n.rawTargetKind ?? '';

    // Handle kinds that don't map to targetType cleanly
    if (kind == 'aiInsights') {
      if (widget.isTherapist) {
        // Navigate to patient details
        if (childId.isNotEmpty && parentId.isNotEmpty) {
          String childName = '';
          try {
            final childDoc = await FirebaseFirestore.instance
                .collection('parents').doc(parentId)
                .collection('children').doc(childId).get();
            childName = childDoc.data()?['name'] as String? ?? '';
          } catch (_) {}
          if (!mounted) return;
          final child = ChildModel(
            childId: childId,
            parentId: parentId,
            name: childName,
            diagnosisType: '',
            severityLevel: 1,
          );
          context.push(Routes.patientDetails, extra: PatientDetailArgs(
            patient: child,
            therapistId: FirebaseAuth.instance.currentUser?.uid ?? '',
          ));
        }
      } else {
        // Navigate to AI Insights screen
        if (childId.isNotEmpty) {
          String childName = '';
          try {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            final childDoc = await FirebaseFirestore.instance
                .collection('parents').doc(uid)
                .collection('children').doc(childId).get();
            childName = childDoc.data()?['name'] as String? ?? '';
          } catch (_) {}
          if (!mounted) return;
          context.push(Routes.aiInsights, extra: {
            'childId': childId,
            'childName': childName,
          });
        }
      }
      return;
    }

    if (kind == 'linkRequest' || kind == 'patient') {
      context.push(Routes.therapistPatients);
      return;
    }

    if (kind == 'dailyLogReminder' || n.type == 'dailyLogReminder') {
      context.go(Routes.parentHome);
      return;
    }

    switch (n.targetType) {
      case NotificationTargetType.session:
        if (n.targetId?.isNotEmpty == true) {
          context.push(Routes.sessionDetail, extra: n.targetId);
        }
      case NotificationTargetType.appointment:
        if (n.targetId?.isNotEmpty == true) {
          context.push(Routes.sessionDetail, extra: n.targetId);
        }
      case NotificationTargetType.log:
        final logId = n.targetId ?? '';
        if (childId.isEmpty || logId.isEmpty) return;

        String childName = '';
        if (parentId.isNotEmpty) {
          try {
            final childDoc = await FirebaseFirestore.instance
                .collection('parents').doc(parentId)
                .collection('children').doc(childId).get();
            childName = childDoc.data()?['name'] as String? ?? '';
          } catch (_) {}
        }

        if (!mounted) return;

        if (widget.isTherapist) {
          context.push(Routes.logReview, extra: LogReviewArgs(
            parentId: parentId,
            childId: childId,
            childName: childName,
            initialTab: kind == 'incident' ? 1 : 0,
          ));
        } else {
          if (kind == 'incident') {
            final child = ChildModel(
              childId: childId,
              parentId: parentId,
              name: childName,
              diagnosisType: '',
              severityLevel: 1,
            );
            context.push(Routes.incidentDetail,
                extra: IncidentDetailArgs(incidentId: logId, child: child));
          } else if (kind == 'dailySummary') {
            context.push(Routes.dailySummaryDetail, extra: {
              'summaryId': logId,
              'parentId': parentId,
              'childId': childId,
              'childName': childName,
            });
          } else if (kind == 'positiveMoment') {
            context.push(Routes.positiveMomentDetail,
                extra: PositiveMomentDetailArgs(
                  momentId: logId,
                  childId: childId,
                  childName: childName,
                  parentId: parentId,
                ));
          } else {
            context.push(Routes.logHistory, extra: childId);
          }
        }
      case NotificationTargetType.unknown:
        break;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: StreamBuilder<List<NotificationModel>>(
          stream: _repo.notificationsStream(
            uid: _uid,
            isTherapist: widget.isTherapist,
          ),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data
                    ?.where((n) => !n.isRead)
                    .length ??
                0;

            return Column(
              children: [
                _Header(
                  isTherapist: widget.isTherapist,
                  unreadCount: unreadCount,
                  isMarkingAll: _isMarkingAll,
                  hasUnread: unreadCount > 0,
                  onMarkAll: _markAllRead,
                ),
                Expanded(
                  child: _buildBody(snapshot),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<List<NotificationModel>> snapshot) {
    // Loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    // Error
    if (snapshot.hasError) {
      return _ErrorState(onRetry: () => setState(() {}));
    }

    final items = snapshot.data ?? [];

    // Empty
    if (items.isEmpty) {
      return _EmptyState(isTherapist: widget.isTherapist);
    }

    // Group notifications by relative day bucket
    final groups = _groupByDay(items);

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 40),
      itemCount: _countItems(groups),
      itemBuilder: (context, index) {
        return _itemAt(groups, index);
      },
    );
  }

  // ─── Grouping helpers ──────────────────────────────────────────────────────

  /// Returns a list of [_DayGroup], each containing a label and its items.
  List<_DayGroup> _groupByDay(List<NotificationModel> items) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));


    final todayItems = <NotificationModel>[];
    final yesterdayItems = <NotificationModel>[];
    final earlierItems = <NotificationModel>[];

    for (final n in items) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (!d.isBefore(todayStart)) {
        todayItems.add(n);
      } else if (!d.isBefore(yesterdayStart)) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    return [
      if (todayItems.isNotEmpty) _DayGroup('Today', todayItems),
      if (yesterdayItems.isNotEmpty) _DayGroup('Yesterday', yesterdayItems),
      if (earlierItems.isNotEmpty) _DayGroup('Earlier', earlierItems),
    ];
  }

  int _countItems(List<_DayGroup> groups) {
    // Each group contributes: 1 header + N tiles.
    return groups.fold(0, (sum, g) => sum + 1 + g.items.length);
  }

  Widget _itemAt(List<_DayGroup> groups, int index) {
    int offset = 0;
    for (final group in groups) {
      if (index == offset) return _SectionHeader(label: group.label);
      offset++;
      final localIndex = index - offset;
      if (localIndex < group.items.length) {
        final n = group.items[localIndex];
        return NotificationTile(
          key: ValueKey(n.id),
          model: n,
          onTap: () async {
            if (!n.isRead) await _markRead(n.id);
            if (mounted) _navigate(n);
          },
        );
      }
      offset += group.items.length;
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header with orange gradient, back button, "Mark all read" pill
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.isTherapist,
    required this.unreadCount,
    required this.isMarkingAll,
    required this.hasUnread,
    required this.onMarkAll,
  });

  final bool isTherapist;
  final int unreadCount;
  final bool isMarkingAll;
  final bool hasUnread;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFA8601), Color(0xFFFB9E34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        topPadding + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl2,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go(
              isTherapist ? Routes.therapistHome : Routes.parentHome,
            ),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icons/icon_back.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.textWhite,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title + unread sub-label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    '$unreadCount unread',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),

          // Mark all read pill
          if (hasUnread)
            GestureDetector(
              onTap: isMarkingAll ? null : onMarkAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: isMarkingAll
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textWhite,
                        ),
                      )
                    : Text(
                        'Mark all read',
                        style: AppTextStyles.tag.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header ("Today", "Yesterday", "Earlier")
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isTherapist});

  final bool isTherapist;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textSubtle,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No notifications yet',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isTherapist
                  ? 'Updates about patients, sessions, and logs will appear here.'
                  : 'Updates about your children, sessions, and logs will appear here.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSubtle,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textSubtle,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Couldn\'t load notifications',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data helpers
// ─────────────────────────────────────────────────────────────────────────────

class _DayGroup {
  const _DayGroup(this.label, this.items);
  final String label;
  final List<NotificationModel> items;
}
