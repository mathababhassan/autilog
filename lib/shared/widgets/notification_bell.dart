import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../features/notifications/data/notification_repository.dart';

/// White notification bell + unread-count badge for the orange home headers.
/// Streams the signed-in user's unread count and opens [route] on tap.
/// Shared by both the parent and therapist home headers — pass [isTherapist]
/// so it reads the right notifications subcollection.
class NotificationBell extends StatelessWidget {
  NotificationBell({
    super.key,
    required this.route,
    required this.isTherapist,
    this.size = 36,
    NotificationRepository? repository,
  }) : _repository = repository ?? NotificationRepository();

  final String route;
  final bool isTherapist;

  /// Diameter of the translucent circle — matches the sibling profile
  /// avatar (36 on both home screens).
  final double size;
  final NotificationRepository _repository;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return GestureDetector(
      onTap: () => context.push(route),
      behavior: HitTestBehavior.opaque,
      child: StreamBuilder<int>(
        stream: _repository.unreadCountStream(
          uid: uid,
          isTherapist: isTherapist,
        ),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textWhite,
                    size: size * 0.55,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(
                          minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: AppColors.textWhite, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: AppTextStyles.tag.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
