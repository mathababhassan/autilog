import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/notification_model.dart';
import 'notification_icon.dart';

/// A single row in the notifications list.
///
/// Shows:
///  • Coloured circular icon on the left (varies by [NotificationModel.type]).
///  • Title + body text in the centre.
///  • An orange dot on the top-right when [model.isRead] is false.
///  • A relative timestamp at the bottom-left ("1h ago", "Yesterday", …).
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.model,
    required this.onTap,
  });

  final NotificationModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            NotificationIconWidget(type: model.type),
            const SizedBox(width: AppSpacing.md),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    model.title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Body
                  Text(
                    model.body,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSubtle,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Timestamp
                  Text(
                    _relativeTime(model.createdAt),
                    style: AppTextStyles.tag.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Unread dot
            if (!model.isRead)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ─── relative time helper ──────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
