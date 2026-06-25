import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Streams and displays therapist comments on a log entry.
///
/// Works for all three log types — pass the correct [logCollection]:
///   'dailySummaries' | 'incidents' | 'positiveMoments'
///
/// Comments live at:
///   parents/{parentId}/children/{childId}/{logCollection}/{logId}/comments/{commentId}
class TherapistCommentsSection extends StatelessWidget {
  const TherapistCommentsSection({
    super.key,
    required this.parentId,
    required this.childId,
    required this.logCollection,
    required this.logId,
  });

  final String parentId;
  final String childId;
  final String logCollection;
  final String logId;

  @override
  Widget build(BuildContext context) {
    final commentsRef = FirebaseFirestore.instance
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection(logCollection)
        .doc(logId)
        .collection('comments')
        .orderBy('createdAt', descending: false);

    return StreamBuilder<QuerySnapshot>(
      stream: commentsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.secondary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Therapist Comments',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                if (docs.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${docs.length}',
                      style: AppTextStyles.tag.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Text(
                  'No comments from your therapist yet.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSubtle,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _CommentCard(data: data);
              }),
          ],
        );
      },
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rawName = data['therapistName'] as String? ?? 'Therapist';
    final therapistName = rawName.startsWith('Dr.') ? rawName : 'Dr. $rawName';
    final comment = data['text'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary20,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border(
          left: BorderSide(color: AppColors.secondary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  therapistName.isNotEmpty
                      ? therapistName[0].toUpperCase()
                      : 'T',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  therapistName,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (createdAt != null)
                Text(
                  _formatDate(createdAt),
                  style: AppTextStyles.tag.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            height: 1,
            color: AppColors.secondary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            comment,
            style: AppTextStyles.body.copyWith(color: AppColors.textMain),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${d.day} ${months[d.month - 1]} · $h:$m $period';
  }
}