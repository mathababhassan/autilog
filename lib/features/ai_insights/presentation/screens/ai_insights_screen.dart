import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/constants/routes.dart';

class AIInsightsScreen extends StatelessWidget {
  final String childId;
  final String childName;

  const AIInsightsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    final parentId = FirebaseAuth.instance.currentUser?.uid;

    if (parentId == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('aiInsights')
          .doc('current')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : null;

        final isUnlocked = data?['isUnlocked'] ?? false;
        final daysLogged = (data?['daysLogged'] ?? 0) as int;

        if (!isUnlocked) {
          return _LockedScreen(
            childId: childId,
            childName: childName,
            daysLogged: daysLogged,
          );
        }

        final weeklyInsights = data?['weeklyInsights'] as Map<String, dynamic>?;
        final generatedAt = data?['generatedAt'] as Timestamp?;

        return _UnlockedScreen(
          childId: childId,
          childName: childName,
          weeklyInsights: weeklyInsights ?? {},
          generatedAt: generatedAt,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// P-41 Locked State
// ─────────────────────────────────────────────────────────────────────────────

class _LockedScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final int daysLogged;

  const _LockedScreen({
    required this.childId,
    required this.childName,
    required this.daysLogged,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (7 - daysLogged).clamp(0, 7);
    final motivationText = daysLogged == 0
        ? 'Great start!'
        : daysLogged < 3
        ? 'Keep going!'
        : daysLogged < 6
        ? 'Almost there!'
        : 'One more day!';

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
          color: AppColors.textMain,
        ),
        title: Text(
          'AI Insights',
          style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary20,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              childName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.secondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Powered by AutiLog AI',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Day progress circles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) {
                final filled = i < daysLogged;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : AppColors.inputFill,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              '$daysLogged days logged · $remaining more to unlock',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              motivationText,
              style: AppTextStyles.heading1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'AutiLog AI needs at least 7 logged days to generate personalised insights for $childName. You have $daysLogged — log $remaining more to unlock.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSubtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Teaser card
            Container(
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
                      Icon(Icons.auto_awesome, color: AppColors.secondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'What AutiLog AI is building for $childName',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _TeaserItem(icon: Icons.description_outlined, text: 'Weekly AI Summary — ${childName}\'s week in plain language'),
                  const SizedBox(height: 12),
                  _TeaserItem(icon: Icons.trending_up, text: 'Progress Direction — better or harder than last week'),
                  const SizedBox(height: 12),
                  _TeaserItem(icon: Icons.lightbulb_outline, text: 'Personalised Tips — based on ${childName}\'s patterns'),
                  const SizedBox(height: 12),
                  _TeaserItem(icon: Icons.star_outline, text: 'Positive Moments Highlight'),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Insights update weekly. Log any 7 days in a month to unlock — no streaks needed.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(Routes.dailySummary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(
                  "Log Today's Summary",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push(Routes.logHistory),
              child: Text(
                'View my log history',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The more you log, the more personalised ${childName}\'s insights become.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// P-40 Unlocked State
// ─────────────────────────────────────────────────────────────────────────────

class _UnlockedScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final Map<String, dynamic> weeklyInsights;
  final Timestamp? generatedAt;

  const _UnlockedScreen({
    required this.childId,
    required this.childName,
    required this.weeklyInsights,
    this.generatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final summary = weeklyInsights['summary'] as String? ?? '';
    final progressDirection = weeklyInsights['progressDirection'] as String? ?? 'stable';
    final tips = (weeklyInsights['tips'] as List<dynamic>?)?.cast<String>() ?? [];
    final positiveMomentsHighlight = weeklyInsights['positiveMomentsHighlight'] as String? ?? '';
    final incidentPattern = weeklyInsights['incidentPattern'] as String? ?? '';

    final updatedDate = generatedAt != null
        ? DateFormat('EEE d MMM yyyy').format(generatedAt!.toDate())
        : '';

    final directionColor = progressDirection == 'improving'
        ? AppColors.success
        : progressDirection == 'needs_attention'
        ? AppColors.accentRed
        : AppColors.warning;

    final directionLabel = progressDirection == 'improving'
        ? '+ IMPROVING'
        : progressDirection == 'needs_attention'
        ? '! NEEDS ATTENTION'
        : '= STABLE';

    final directionTitle = progressDirection == 'improving'
        ? 'Better week than last'
        : progressDirection == 'needs_attention'
        ? 'Needs more support'
        : 'Similar to last week';

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
          color: AppColors.textMain,
        ),
        title: Text(
          'AI Insights',
          style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary20,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              childName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Powered by AutiLog AI',
                      style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                if (updatedDate.isNotEmpty)
                  Text(
                    'Updated $updatedDate',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress direction card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary20,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: directionColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      directionTitle,
                      style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: directionColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      directionLabel,
                      style: AppTextStyles.tag.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weekly summary card
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.secondary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Weekly Summary',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.secondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Generated by AutiLog AI',
                        style: AppTextStyles.tag.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Positive moments card
            if (positiveMomentsHighlight.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POSITIVE MOMENTS',
                      style: AppTextStyles.tag.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      positiveMomentsHighlight,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Tips
            if (tips.isNotEmpty) ...[
              for (int i = 0; i < tips.length; i++) ...[
                Container(
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
                          Icon(
                            i == 0 ? Icons.bedtime_outlined : Icons.shield_outlined,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            i == 0 ? 'SLEEP TIP' : 'STRATEGY TIP',
                            style: AppTextStyles.tag.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(tips[i], style: AppTextStyles.body),
                    ],
                  ),
                ),
                if (i < tips.length - 1) const SizedBox(height: 16),
              ],
            ],
            const SizedBox(height: 16),

            // Incident pattern
            if (incidentPattern.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error20,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'INCIDENT PATTERN',
                          style: AppTextStyles.tag.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(incidentPattern, style: AppTextStyles.body),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(Routes.dailySummary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(
                  "Log Today's Summary",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push(Routes.logHistory),
                child: Text(
                  'View my log history',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teaser Item Widget
// ─────────────────────────────────────────────────────────────────────────────

class _TeaserItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TeaserItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.textMain),
          ),
        ),
      ],
    );
  }
}