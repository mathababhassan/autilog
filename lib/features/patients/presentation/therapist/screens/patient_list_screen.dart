import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/child_model.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../bloc/patient_list_bloc.dart';
import '../../../bloc/patient_list_event.dart';
import '../../../bloc/patient_list_state.dart';
import '../../../data/pending_request_display.dart';
import '../widgets/therapist_bottom_nav.dart';
import 'patient_details_screen.dart';


// ─── Screen ───────────────────────────────────────────────────

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<PatientListBloc>().add(const PatientListStarted());
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientListBloc, PatientListState>(
      listener: (context, state) {
        if (state is PatientListLoaded) {
          if (state.actionStatus == PatientListActionStatus.success &&
              state.actionMessage != null) {
            AppSnackbar.showSuccess(context, state.actionMessage!);
          } else if (state.actionStatus == PatientListActionStatus.error &&
              state.actionMessage != null) {
            AppSnackbar.showError(context, state.actionMessage!);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: BlocBuilder<PatientListBloc, PatientListState>(
          builder: (context, state) {

            if (state is PatientListLoading || state is PatientListInitial) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              );
            }

            if (state is PatientListError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Text(state.message,
                      style: AppTextStyles.body.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center),
                ),
              );
            }

            if (state is PatientListLoaded) {
              final filteredPending = _searchQuery.isEmpty
                  ? state.pendingRequests
                  : state.pendingRequests
                      .where((r) =>
                          r.childName.toLowerCase().contains(_searchQuery) ||
                          r.parentName.toLowerCase().contains(_searchQuery))
                      .toList();

              final filteredActive = _searchQuery.isEmpty
                  ? state.activePatients
                  : state.activePatients
                      .where((p) =>
                          p.name.toLowerCase().contains(_searchQuery) ||
                          p.diagnosisType.toLowerCase().contains(_searchQuery))
                      .toList();

              final isActionInProgress =
                  state.actionStatus == PatientListActionStatus.inProgress;

              return _buildContent(
                  context, filteredPending, filteredActive, isActionInProgress);
            }

            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar:
            const TherapistBottomNav(activeTab: TherapistNavTab.patients),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 56,
      titleSpacing: 0,
      leading: GestureDetector(
        onTap: () => context.go(Routes.therapistHome),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xl),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/icon_back.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                  AppColors.textMain, BlendMode.srcIn),
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Text('Patients',
          style: AppTextStyles.heading1.copyWith(color: AppColors.textMain)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.borderInactive),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<PendingRequestDisplay> pending,
    List<ChildModel> active,
    bool isActionInProgress,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl2, AppSpacing.xl, 0),
            child: _SearchBar(controller: _searchController),
          ),
          const SizedBox(height: AppSpacing.xl2),

          // Pending section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _PendingSectionHeader(count: pending.length),
          ),
          const SizedBox(height: AppSpacing.md),

          // Pending cards — horizontal scroll, breaks out of body padding
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _EmptyState(
                icon: Icons.inbox_outlined,
                message: 'No pending requests',
              ),
            )
          else
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: pending.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final request = pending[index];
                  return SizedBox(
                    width: 180,
                    child: _PendingCard(
                      request: request,
                      isActionInProgress: isActionInProgress,
                      onAccept: () =>
                          context.read<PatientListBloc>().add(
                                PendingRequestAccepted(
                                  requestId: request.requestId,
                                  parentId: request.parentId,
                                  childId: request.childId,
                                ),
                              ),
                      onReject: () =>
                          context.read<PatientListBloc>().add(
                                PendingRequestRejected(
                                    requestId: request.requestId),
                              ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.xl2),

          // My Patients header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'My Patients',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Patient cards
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _EmptyState(
                icon: Icons.people_outline,
                message: 'No linked patients yet',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: active.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final patient = active[index];
                  return _PatientCard(
                    patient: patient,
                    isActionInProgress: isActionInProgress,
                    onViewDetails: () {
                      if (patient.parentId.isEmpty) {
                        AppSnackbar.showError(
                          context,
                          'Patient link data is incomplete.',
                        );
                        return;
                      }
                      context.push(
                        Routes.therapistPatientDetail,
                        extra: PatientDetailsArgs(patient: patient),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.xl2),
        ],
      ),
    );
  }

}

// ─── Search bar ───────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderInactive),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg),
          const Icon(Icons.search_outlined,
              color: AppColors.textPlaceholder, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.body.copyWith(
                  fontSize: 14, height: 1, color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Search Patient',
                hintStyle: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    height: 1,
                    color: AppColors.textPlaceholder),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ─── Pending section header ───────────────────────────────────

class _PendingSectionHeader extends StatelessWidget {
  const _PendingSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Pending Requests',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.11,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pending card (180px fixed, horizontal scroll) ────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.request,
    required this.isActionInProgress,
    required this.onAccept,
    required this.onReject,
  });

  final PendingRequestDisplay request;
  final bool isActionInProgress;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderInactive, width: 1.27),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + severity badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PendingAvatar(name: request.childName),
              _PendingSeverityBadge(severityLevel: request.severityLevel),
            ],
          ),
          const SizedBox(height: 9),
          // Name
          Text(
            request.childName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.21,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 1),
          // Parent name
          Text(
            'Parent: ${request.parentName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSubtle,
              letterSpacing: -0.14,
              height: 1.4,
            ),
          ),
          const Spacer(),
          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 74,
                child: GestureDetector(
                  onTap: isActionInProgress ? null : onReject,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.error20, width: 1.27),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE84545),
                        letterSpacing: -0.14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 71,
                child: GestureDetector(
                  onTap: isActionInProgress ? null : onAccept,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingAvatar extends StatelessWidget {
  const _PendingAvatar({required this.name});

  final String name;

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary20,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12.54,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
          letterSpacing: 0.13,
        ),
      ),
    );
  }
}

class _PendingSeverityBadge extends StatelessWidget {
  const _PendingSeverityBadge({required this.severityLevel});

  final int severityLevel;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color text;
    final String label;

    switch (severityLevel) {
      case 1:
        bg = AppColors.secondary20;
        text = AppColors.secondary;
        label = 'ASD L1';
      case 2:
        bg = const Color(0xFFFCEFE2);
        text = const Color(0xFFE5731A);
        label = 'ASD L2';
      default:
        bg = AppColors.error20;
        text = AppColors.error;
        label = 'ASD L3';
    }

    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.1,
          height: 1,
        ),
      ),
    );
  }
}

// ─── Active patient card ──────────────────────────────────────

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.isActionInProgress,
    required this.onViewDetails,
  });

  final ChildModel patient;
  final bool isActionInProgress;
  final VoidCallback onViewDetails;

  bool get _isAlert => patient.severityLevel == 3;

  @override
  Widget build(BuildContext context) {
    final cardColor = _isAlert ? AppColors.accentRed20 : AppColors.surfaceDefault;
    final borderColor = _isAlert ? AppColors.error : AppColors.borderInactive;
    final dividerColor = _isAlert ? AppColors.error : AppColors.dividerLight;
    final infoTextColor =
        _isAlert ? AppColors.textMain : AppColors.textDisabled;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: _isAlert ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PatientAvatar(name: patient.name),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textHighContrast,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_isAlert) ...[
                            const SizedBox(height: 2),
                            Text(
                              '4 High severity incidents this week',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ActiveSeverityBadge(severityLevel: patient.severityLevel),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(height: 1, thickness: 1, color: dividerColor),
          const SizedBox(height: 8),

          // Session info + View Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isAlert) ...[
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        iconSize: 14,
                        text: 'Friday · 2:00 PM',
                        color: infoTextColor,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _InfoRow(
                      icon: Icons.access_time_outlined,
                      iconSize: 14,
                      text: 'Last log 2 days ago',
                      color: infoTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isActionInProgress ? null : onViewDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(56),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'View Details',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientAvatar extends StatelessWidget {
  const _PatientAvatar({required this.name});

  final String name;

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary20,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _ActiveSeverityBadge extends StatelessWidget {
  const _ActiveSeverityBadge({required this.severityLevel});

  final int severityLevel;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color text;

    switch (severityLevel) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'ASD - L $severityLevel',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.11,
          height: 15.4 / 11,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconSize,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final double iconSize;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: color,
            letterSpacing: -0.14,
            height: 16.8 / 12,
          ),
        ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textPlaceholder),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
          ),
        ],
      ),
    );
  }
}

