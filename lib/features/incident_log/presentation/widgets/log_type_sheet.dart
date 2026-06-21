import '../../../../core/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/routes.dart';
import '../screens/incident_form_screen.dart';
import '../screens/quick_log_screen.dart';
import '../../../positive_moment/positive_moment_route_args.dart';

void showLogTypeSheet(
  BuildContext context,
  String patientId,
  String patientName,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        LogTypeSheet(patientId: patientId, patientName: patientName),
  );
}

class LogTypeSheet extends StatelessWidget {
  final String patientId;
  final String patientName;

  const LogTypeSheet({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'What would you like to log?',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'for $patientName · ${DateFormat('EEE d MMM yyyy').format(DateTime.now())}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Column(
                children: [
                  _LogTypeCard(
                    title: 'Behavioral Incident',
                    description: 'Meltdowns, refusal, or difficult moments to track',
                    bgColor: AppColors.primary20,
                    borderColor: AppColors.secondaryOrange,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        Routes.incidentForm,
                        extra: IncidentFormArgs(
                          patientId: patientId,
                          patientName: patientName,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LogTypeCard(
                    title: 'Positive Moment',
                    description: 'Social wins, breakthroughs, or moments worth celebrating',
                    bgColor: AppColors.secondary20,
                    borderColor: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        Routes.positiveMomentForm,
                        extra: PositiveMomentFormArgs(
                          patientId: patientId,
                          patientName: patientName,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LogTypeCard(
                    title: 'Quick Log (AI)',
                    description: 'Speak or type freely — AI extracts the details for you',
                    bgColor: const Color(0xFFF0F4FF),
                    borderColor: const Color(0xFF6B7FD7),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _QuickLogTypeSheet(
                          patientId: patientId,
                          patientName: patientName,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogTypeSheet extends StatelessWidget {
  const _QuickLogTypeSheet(
      {required this.patientId, required this.patientName});
  final String patientId;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Quick Log — what type?',
              style:
                  AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('AI will extract the structured details from your description.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textDisabled)),
          const SizedBox(height: 20),
          _LogTypeCard(
            title: 'Behavioral Incident',
            description: 'Meltdowns, refusal, or difficult moments',
            bgColor: AppColors.primary20,
            borderColor: AppColors.secondaryOrange,
            onTap: () {
              Navigator.pop(context);
              context.push(
                Routes.quickLogIncident,
                extra: QuickLogArgs(
                  patientId: patientId,
                  patientName: patientName,
                  logType: 'incident',
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _LogTypeCard(
            title: 'Positive Moment',
            description: 'Social wins, breakthroughs, or celebrations',
            bgColor: AppColors.secondary20,
            borderColor: AppColors.secondary,
            onTap: () {
              Navigator.pop(context);
              context.push(
                Routes.quickLogPositiveMoment,
                extra: QuickLogArgs(
                  patientId: patientId,
                  patientName: patientName,
                  logType: 'positiveMoment',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LogTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const _LogTypeCard({
    required this.title,
    required this.description,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.cardPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Transform.flip(
              flipX: true,
              child: SvgPicture.asset(
                'assets/icons/icon_back.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  borderColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
