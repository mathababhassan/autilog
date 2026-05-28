import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/routes.dart';

class AIInsightsPreview extends StatelessWidget {
  final String childId;
  final String childName;

  const AIInsightsPreview({super.key, required this.childId, required this.childName});

  @override
  Widget build(BuildContext context) {
    final parentId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('AIInsightsPreview — parentId: $parentId, childId: $childId');

    if (parentId == null) {
      return const SizedBox.shrink();
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
        debugPrint('snapshot state: ${snapshot.connectionState}');
        debugPrint('snapshot hasData: ${snapshot.hasData}');
        debugPrint('snapshot error: ${snapshot.error}');
        if (snapshot.hasData) {
          debugPrint('snapshot exists: ${snapshot.data!.exists}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildLockedState(context, daysLogged: 0);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        debugPrint('aiInsights data: $data');
        final isUnlocked = data['isUnlocked'] ?? false;
        final daysLogged = data['daysLogged'] ?? 0;

        if (!isUnlocked) {
          return _buildLockedState(context, daysLogged: daysLogged);
        }

        final weeklyInsights = data['weeklyInsights'] as Map<String, dynamic>?;
        final summary = weeklyInsights?['summary'] as String?;

        return _buildUnlockedState(context, summary: summary ?? 'Loading insights...');
      },
    );
  }

  Widget _buildLockedState(BuildContext context, {required int daysLogged}) {
    final remainingDays = 7 - daysLogged;
    final remainingDaysText = remainingDays > 0 ? '$remainingDays more days' : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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
              Icon(Icons.lock_outline, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$daysLogged / 7 days logged',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            daysLogged >= 7
                ? 'Great! AI insights are ready!'
                : 'Log $remainingDaysText to unlock personalized AI insights for ${_getChildName()}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          if (daysLogged < 7) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: daysLogged / 7,
              backgroundColor: AppColors.primary20,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnlockedState(BuildContext context, {required String summary}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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
              Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(
                Routes.aiInsights,
                extra: {'childId': childId, 'childName': childName},
              ),
              child: const Text('See all →'),
            ),
          ),
        ],
      ),
    );
  }

  String _getChildName() {
    return childName;
  }
}