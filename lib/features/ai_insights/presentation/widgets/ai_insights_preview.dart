import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/routes.dart';

class AIInsightsPreview extends StatefulWidget {
  final String childId;
  final String childName;

  const AIInsightsPreview({super.key, required this.childId, required this.childName});

  @override
  State<AIInsightsPreview> createState() => _AIInsightsPreviewState();
}

class _AIInsightsPreviewState extends State<AIInsightsPreview> {
  bool _refreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final parentId = FirebaseAuth.instance.currentUser?.uid;

    if (parentId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('aiInsights')
          .doc('current')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _refreshing) {
          return Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary20,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildLockedState(context, daysLogged: 0);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isUnlocked = data['isUnlocked'] ?? false;
        final daysLogged = data['daysLogged'] ?? 0;

        if (!isUnlocked) {
          return _buildLockedState(context, daysLogged: daysLogged);
        }

        final weeklyInsights = data['weeklyInsights'] as Map<String, dynamic>?;
        final summary = weeklyInsights?['summary'] as String? ?? 'Loading insights...';
        final generatedAt = data['generatedAt'] as Timestamp?;
        final updatedDate = generatedAt != null
            ? 'Updated ${_formatDate(generatedAt.toDate())}'
            : '';

        return _buildUnlockedState(context, summary: summary, updatedDate: updatedDate);
      },
    );
  }

  Widget _buildLockedState(BuildContext context, {required int daysLogged}) {
    final remainingDays = 7 - daysLogged;

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
              Text('AI Insights', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('$daysLogged / 7 days logged',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.secondary)),
          const SizedBox(height: 8),
          Text(
            daysLogged >= 7
                ? 'Great! AI insights are ready!'
                : 'Log $remainingDays more days to unlock personalized AI insights for ${widget.childName}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
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

  Widget _buildUnlockedState(BuildContext context, {required String summary, required String updatedDate}) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('AI Insights', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: _handleRefresh,
                child: Icon(Icons.refresh_rounded, color: AppColors.secondary, size: 20),
              ),
            ],
          ),
          if (updatedDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(updatedDate, style: AppTextStyles.tag.copyWith(color: AppColors.textSubtle)),
          ],
          const SizedBox(height: 12),
          Text(
            summary,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(
                Routes.aiInsights,
                extra: {'childId': widget.childId, 'childName': widget.childName},
              ),
              child: Text(
                'View more →',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}