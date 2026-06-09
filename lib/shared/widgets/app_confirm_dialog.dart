import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// A lightweight, **non-destructive** confirmation dialog: a plain
/// Cancel / confirm choice with a coloured confirm button.
///
/// Use this for reversible or positive actions (e.g. "Mark as completed").
/// For destructive actions that need a typed keyword, use
/// `showAppConfirmationDialog` instead.
///
/// Returns true only if the user taps the confirm button.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  Color confirmColor = AppColors.primary,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      title: Text(title, style: AppTextStyles.heading2),
      content: Text(message, style: AppTextStyles.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: AppColors.textWhite,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
