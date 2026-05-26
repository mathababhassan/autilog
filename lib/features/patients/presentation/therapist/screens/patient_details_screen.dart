import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/child_model.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../bloc/patient_list_bloc.dart';
import '../../../bloc/patient_list_event.dart';
import '../../../bloc/patient_list_state.dart';
import '../../../data/patient_detail_info.dart';
import '../../../data/patient_repository.dart';
import '../widgets/patient_ai_insights_panel.dart';
import '../widgets/patient_recent_log_card.dart';
import '../widgets/patient_session_card.dart';
import '../widgets/remove_patient_dialog.dart';
import '../widgets/therapist_bottom_nav.dart';

class PatientDetailsArgs {
  final ChildModel patient;

  const PatientDetailsArgs({required this.patient});
}

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key, required this.args});

  final PatientDetailsArgs args;

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _repository = PatientRepository();
  PatientDetailInfo? _detail;
  bool _loading = true;
  String? _error;
  bool _aiInsightsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final patient = widget.args.patient;
    if (patient.parentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Could not load patient details.';
      });
      return;
    }

    try {
      final detail = await _repository.fetchPatientDetail(
        parentId: patient.parentId,
        childId: patient.childId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load patient details. Please try again.';
      });
    }
  }

  String get _displayName {
    final name = _detail?.child.name ?? widget.args.patient.name;
    return name.split(' ').first;
  }

  void _showOptionsMenu() {
    final detail = _detail;
    if (detail == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: AppColors.error,
              ),
              title: Text(
                'Remove patient',
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRemoveSheet(detail);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.close,
                color: AppColors.textPlaceholder,
              ),
              title: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _showRemoveSheet(PatientDetailInfo detail) {
    final bloc = context.read<PatientListBloc>();
    final isBusy = bloc.state is PatientListLoaded &&
        (bloc.state as PatientListLoaded).actionStatus ==
            PatientListActionStatus.inProgress;
    if (isBusy) return;

    showRemovePatientSheet(
      context,
      patient: detail.child,
      parentName: detail.parentName,
      onConfirmRemove: () {
        bloc.add(ActivePatientRemoved(
          parentId: detail.child.parentId,
          childId: detail.child.childId,
        ));
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientListBloc, PatientListState>(
      listener: (context, state) {
        if (state is PatientListLoaded &&
            state.actionStatus == PatientListActionStatus.error &&
            state.actionMessage != null) {
          AppSnackbar.showError(context, state.actionMessage!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceDefault,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                title: _loading ? 'Patient' : _displayName,
                onMenuTap: _detail != null ? _showOptionsMenu : null,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        bottomNavigationBar:
            const TherapistBottomNav(activeTab: TherapistNavTab.patients),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null || _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Text(
            _error ?? 'Patient not found',
            style: AppTextStyles.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final detail = _detail!;
    final firstName = detail.child.name.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.lg,
        AppSpacing.screenMargin,
        AppSpacing.xl2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PatientProfileCard(detail: detail),
          const SizedBox(height: AppSpacing.xl2),

          // AI Insights
          InkWell(
            onTap: () => setState(() => _aiInsightsExpanded = !_aiInsightsExpanded),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Insights',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    _aiInsightsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMain,
                  ),
                ],
              ),
            ),
          ),
          if (_aiInsightsExpanded) ...[
            PatientAiInsightsPanel(patientFirstName: firstName),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Recent Logs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Logs',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => AppSnackbar.showError(
                  context,
                  'Log history is coming soon',
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          PatientRecentLogCard(
            dateLabel: 'Thu 17 Apr',
            summary: '2 incidents · Sleep: Bad',
            onReview: () => AppSnackbar.showError(
              context,
              'Log review is coming soon',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PatientRecentLogCard(
            dateLabel: 'Thu 19 Apr',
            summary: '2 incidents · Sleep: Bad',
            onReview: () => AppSnackbar.showError(
              context,
              'Log review is coming soon',
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),

          // Upcoming Sessions
          Text(
            'Upcoming Sessions',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          const PatientSessionCard(
            title: 'Behavioral Therapy',
            timeRange: '1:00 PM – 2:00 PM',
            location: 'Zoom',
          ),
          const SizedBox(height: AppSpacing.sm),
          const PatientSessionCard(
            title: 'Behavioral Therapy',
            timeRange: '1:00 PM – 2:00 PM',
            location: 'Zoom',
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => AppSnackbar.showError(
                context,
                'Session booking is coming soon',
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Book New Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                textStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.onMenuTap});

  final String title;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.borderInactive)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(title, style: AppTextStyles.heading1),
          ),
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.more_horiz, color: AppColors.textMain),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({required this.detail});

  final PatientDetailInfo detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border.all(color: AppColors.borderInactive),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PatientPhotoAvatar(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.child.name,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age ${detail.age}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
              _SeverityBadge(
                label: detail.severityLabel,
                level: detail.child.severityLevel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.borderInactive),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Parent', value: detail.parentName),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Phone', value: detail.parentPhone),
        ],
      ),
    );
  }
}

class _PatientPhotoAvatar extends StatelessWidget {
  const _PatientPhotoAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary20,
        border: Border.all(color: AppColors.secondary40, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.face_retouching_natural_outlined,
        size: 28,
        color: AppColors.secondary,
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.label, required this.level});

  final String label;
  final int level;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color text;

    switch (level) {
      case 1:
        bg = AppColors.secondary20;
        text = AppColors.secondary;
      case 2:
        bg = AppColors.secondaryOrange20;
        text = AppColors.secondaryOrange;
      default:
        bg = AppColors.error20;
        text = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.tag.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
