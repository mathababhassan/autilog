import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Circular icon used on each [NotificationTile].
///
/// The colour and icon are chosen from the notification [type] string so that
/// the design matches the Figma reference exactly:
///
/// | type                  | icon              | bg colour          |
/// |-----------------------|-------------------|--------------------|
/// | session_reminder      | notifications     | primary (orange)   |
/// | new_comment           | chat_bubble       | secondary (teal)   |
/// | new_comment_on_a_log  | chat_bubble       | secondary (teal)   |
/// | weekly_insights       | auto_graph        | accent (blue)      |
/// | session_scheduled     | calendar_month    | secondary (teal)   |
/// | session_notes_added   | description       | secondary (teal)   |
/// | daily_log_reminder    | edit_note         | secondaryOrange    |
/// | session_cancelled     | event_busy        | accentRed          |
/// | new_patient_request   | person_add        | secondaryOrange    |
/// | high_severity         | warning           | accentRed          |
/// | new_log_added         | edit_note         | secondaryOrange    |
/// | (fallback)            | notifications     | labelInactive      |
class NotificationIconWidget extends StatelessWidget {
  const NotificationIconWidget({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final _IconConfig cfg = _configFor(type);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cfg.bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(cfg.icon, color: cfg.fg, size: 20),
    );
  }

  static _IconConfig _configFor(String type) {
    final t = type.toLowerCase();

    if (t.contains('session_reminder') || t.contains('reminder')) {
      return _IconConfig(
        icon: Icons.notifications_outlined,
        bg: AppColors.primary20,
        fg: AppColors.primary,
      );
    }
    if (t.contains('comment')) {
      return _IconConfig(
        icon: Icons.chat_bubble_outline_rounded,
        bg: AppColors.secondary20,
        fg: AppColors.secondary,
      );
    }
    if (t.contains('insight') || t.contains('ai')) {
      return _IconConfig(
        icon: Icons.auto_graph_rounded,
        bg: AppColors.secondary20,
        fg: AppColors.accent,
      );
    }
    if (t.contains('session_scheduled') || t.contains('scheduled')) {
      return _IconConfig(
        icon: Icons.calendar_month_outlined,
        bg: AppColors.secondary20,
        fg: AppColors.secondary,
      );
    }
    if (t.contains('notes_added') || t.contains('notes')) {
      return _IconConfig(
        icon: Icons.description_outlined,
        bg: AppColors.secondary20,
        fg: AppColors.secondary,
      );
    }
    if (t.contains('cancelled') || t.contains('canceled')) {
      return _IconConfig(
        icon: Icons.event_busy_rounded,
        bg: AppColors.accentRed20,
        fg: AppColors.accentRed,
      );
    }
    if (t.contains('daily_log') || t.contains('log_reminder')) {
      return _IconConfig(
        icon: Icons.edit_note_rounded,
        bg: AppColors.secondaryOrange20,
        fg: AppColors.secondaryOrange,
      );
    }
    if (t.contains('new_log') || t.contains('log_added')) {
      return _IconConfig(
        icon: Icons.edit_note_rounded,
        bg: AppColors.secondaryOrange20,
        fg: AppColors.secondaryOrange,
      );
    }
    if (t.contains('high_severity') || t.contains('severity')) {
      return _IconConfig(
        icon: Icons.warning_amber_rounded,
        bg: AppColors.accentRed20,
        fg: AppColors.accentRed,
      );
    }
    if (t.contains('patient_request') || t.contains('new_patient')) {
      return _IconConfig(
        icon: Icons.person_add_outlined,
        bg: AppColors.secondaryOrange20,
        fg: AppColors.secondaryOrange,
      );
    }
    if (t.contains('appointment')) {
      return _IconConfig(
        icon: Icons.event_outlined,
        bg: AppColors.secondary20,
        fg: AppColors.secondary,
      );
    }

    // Fallback
    return _IconConfig(
      icon: Icons.notifications_none_rounded,
      bg: AppColors.inputFill,
      fg: AppColors.textSubtle,
    );
  }
}

class _IconConfig {
  const _IconConfig({
    required this.icon,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final Color bg;
  final Color fg;
}
