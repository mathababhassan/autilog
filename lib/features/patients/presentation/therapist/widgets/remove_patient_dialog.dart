import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/child_model.dart';

/// T-13 — Remove patient confirmation bottom sheet.
void showRemovePatientSheet(
  BuildContext context, {
  required ChildModel patient,
  required String parentName,
  required VoidCallback onConfirmRemove,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _RemovePatientSheet(
      patient: patient,
      parentName: parentName,
      onConfirmRemove: () {
        Navigator.of(sheetContext).pop();
        onConfirmRemove();
      },
      onKeep: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _RemovePatientSheet extends StatelessWidget {
  const _RemovePatientSheet({
    required this.patient,
    required this.parentName,
    required this.onConfirmRemove,
    required this.onKeep,
  });

  final ChildModel patient;
  final String parentName;
  final VoidCallback onConfirmRemove;
  final VoidCallback onKeep;

  String get _initials {
    final parts = patient.name.trim().split(' ').where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return '?';
    if (list.length == 1) return list.first[0].toUpperCase();
    return '${list.first[0]}${list.last[0]}'.toUpperCase();
  }

  String get _severitySubtitle => 'ASD Level ${patient.severityLevel}';

  @override
  Widget build(BuildContext context) {
    final firstName = patient.name.split(' ').first;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        MediaQuery.paddingOf(context).bottom + AppSpacing.xl2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_remove_outlined,
              color: AppColors.textWhite,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Remove ${patient.name}?',
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              border: Border.all(color: AppColors.borderInactive),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_severitySubtitle · Parent: $parentName',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Removing $firstName will end your access to all their logs and session history.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPlaceholder,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.secondary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Parent will be notified immediately.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl2),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onConfirmRemove,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
              ),
              child: Text(
                'Remove Patient',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onKeep,
            child: Text(
              'Keep patient',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
