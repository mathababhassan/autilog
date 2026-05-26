import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/models/child_model.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../bloc/child_profile_bloc.dart';
import '../../bloc/child_profile_event.dart';
import '../../bloc/child_profile_state.dart';
import '../../bloc/link_status.dart';

// ─── Args ─────────────────────────────────────────────────────────────────────

class ChildProfileArgs {
  const ChildProfileArgs({required this.parentId, required this.childId});
  final String parentId;
  final String childId;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChildProfileScreen extends StatelessWidget {
  const ChildProfileScreen({super.key, required this.args});
  final ChildProfileArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChildProfileBloc, ChildProfileState>(
      listenWhen: (prev, curr) {
        if (curr is! ChildProfileLoaded || prev is! ChildProfileLoaded) {
          return false;
        }
        return prev.actionStatus != curr.actionStatus;
      },
      listener: (context, state) {
        if (state is! ChildProfileLoaded) return;
        if (state.actionStatus == ActionStatus.success) {
          // Close the sheet (it's the top route when listener fires).
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          final email = state.linkStatus is PendingLink
              ? (state.linkStatus as PendingLink).therapistEmail
              : '';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => _RequestSentDialog(
                therapistEmail: email,
                onDone: () => Navigator.pop(context),
              ),
            );
          });
        } else if (state.actionStatus == ActionStatus.error &&
            state.actionMessage != null) {
          AppSnackbar.showError(context, state.actionMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surfaceDefault,
          body: SafeArea(
            child: Column(
              children: [
                _NavBar(title: _childName(state)),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _childName(ChildProfileState state) =>
      state is ChildProfileLoaded ? state.child.name : 'Child Profile';

  Widget _buildBody(BuildContext context, ChildProfileState state) {
    if (state is ChildProfileInitial || state is ChildProfileLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      );
    }

    if (state is ChildProfileError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.message,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.read<ChildProfileBloc>().add(
                      ChildProfileStarted(
                        parentId: args.parentId,
                        childId: args.childId,
                      ),
                    ),
                child: Text(
                  'Try again',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = state as ChildProfileLoaded;
    return SingleChildScrollView(
      child: Column(
        children: [
          _HeroBlock(child: loaded.child),
          _InfoSection(
            label: 'Child Info',
            children: [
              _InfoRow(
                label: 'Date of Birth',
                value: _formatDate(loaded.child.dateOfBirth),
              ),
              const _InfoDivider(),
              _InfoRow(
                label: 'Age',
                value: '${_age(loaded.child.dateOfBirth)} years old',
              ),
              const _InfoDivider(),
              _InfoRow(
                label: 'Diagnosis',
                value: loaded.child.diagnosisType.isNotEmpty
                    ? loaded.child.diagnosisType
                    : '—',
              ),
              const _InfoDivider(),
              _InfoRow(
                label: 'Severity',
                value: 'ASD Level ${loaded.child.severityLevel}',
              ),
            ],
          ),
          _InfoSection(
            label: 'Therapist',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.md,
                  AppSpacing.screenMargin,
                  AppSpacing.lg,
                ),
                child: _buildLinkCard(context, loaded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl4),
        ],
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, ChildProfileLoaded state) {
    final isLoading = state.actionStatus == ActionStatus.inProgress;
    return switch (state.linkStatus) {
      NoLink() => _NoLinkCard(
          isLoading: isLoading,
          onLink: () => _showLinkSheet(context),
        ),
      PendingLink(:final requestId, :final therapistEmail) => _PendingCard(
          therapistEmail: therapistEmail,
          isLoading: isLoading,
          onCancel: () => _confirmCancel(context, requestId),
        ),
      ActiveLink(
        :final therapistId,
        :final therapistName,
        :final clinicName,
        :final specialisation,
        :final phone,
      ) =>
        _ActiveCard(
          therapistName: therapistName,
          clinicName: clinicName,
          specialisation: specialisation,
          phone: phone,
          isLoading: isLoading,
          onRevoke: () => _confirmRevoke(
            context,
            therapistId,
            state.child.childId,
          ),
        ),
    };
  }

  void _showLinkSheet(BuildContext context) {
    final bloc = context.read<ChildProfileBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const _LinkRequestSheet(),
      ),
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text('Cancel Request', style: AppTextStyles.heading2),
        content: Text(
          'Are you sure you want to cancel the link request?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep it',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<ChildProfileBloc>()
          .add(LinkRequestCancelled(requestId: requestId));
    }
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    String therapistId,
    String childId,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Revoke Access',
      description:
          "The therapist will immediately lose access to your child's logs.",
      confirmText: 'revoke',
      confirmButtonLabel: 'Revoke Access',
    );
    if (confirmed == true && context.mounted) {
      context.read<ChildProfileBloc>().add(
            TherapistAccessRevoked(
                therapistId: therapistId, childId: childId),
          );
    }
  }
}

// ─── Nav bar ──────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(
          bottom: BorderSide(color: AppColors.borderInactive),
        ),
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
            behavior: HitTestBehavior.opaque,
            child: SvgPicture.asset(
              'assets/icons/icon_back.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                  AppColors.textMain, BlendMode.srcIn),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style:
                    AppTextStyles.heading2.copyWith(color: AppColors.textMain),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ─── Hero block ───────────────────────────────────────────────────────────────

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.child});
  final ChildModel child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 22),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Column(
        children: [
          _AvatarCircle(initials: _initials(child.name), size: 82),
          const SizedBox(height: 10),
          Text(
            child.name,
            style:
                AppTextStyles.heading1.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: 4),
          Text(
            'ASD Level ${child.severityLevel} · ${_age(child.dateOfBirth)} yrs old',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

// ─── Info section / row ───────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin, 14, AppSpacing.screenMargin, 6),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.tag.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
            ),
          ),
        ),
        Container(
          color: AppColors.surfaceDefault,
          child: Column(children: children),
        ),
        const Divider(
          height: 1,
          indent: AppSpacing.screenMargin,
          endIndent: AppSpacing.screenMargin,
          color: AppColors.dividerLight,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: AppSpacing.screenMargin,
      endIndent: AppSpacing.screenMargin,
      color: AppColors.dividerLight,
    );
  }
}

// ─── Link status cards ────────────────────────────────────────────────────────

class _NoLinkCard extends StatelessWidget {
  const _NoLinkCard({required this.isLoading, required this.onLink});
  final bool isLoading;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border.all(color: AppColors.borderInactive),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_off_rounded,
                  color: AppColors.textDisabled, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'No therapist linked',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.textMain),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Link a therapist to share your child's logs with them.",
            style: AppTextStyles.body
                .copyWith(color: AppColors.textPlaceholder),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Link a Therapist',
            isLoading: isLoading,
            onPressed: onLink,
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.therapistEmail,
    required this.isLoading,
    required this.onCancel,
  });
  final String therapistEmail;
  final bool isLoading;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary20,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Request Pending',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.textMain),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            therapistEmail,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs2),
          Text(
            'Waiting for the therapist to respond.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.error),
            )
          else
            GestureDetector(
              onTap: onCancel,
              child: Text(
                'Cancel request',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.therapistName,
    required this.clinicName,
    required this.specialisation,
    this.phone,
    required this.isLoading,
    required this.onRevoke,
  });
  final String therapistName;
  final String clinicName;
  final String specialisation;
  final String? phone;
  final bool isLoading;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.secondary20,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Linked Therapist',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.textMain),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            therapistName,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (clinicName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs2),
            Text(
              clinicName,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPlaceholder),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Specialisation',
            value: specialisation.isNotEmpty ? specialisation : '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Phone', value: phone ?? '—'),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.error),
            )
          else
            GestureDetector(
              onTap: onRevoke,
              child: Text(
                'Revoke access',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDisabled,
          ),
        ),
        const SizedBox(height: AppSpacing.xs2),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}

// ─── Link request sheet ───────────────────────────────────────────────────────

class _LinkRequestSheet extends StatefulWidget {
  const _LinkRequestSheet();

  @override
  State<_LinkRequestSheet> createState() => _LinkRequestSheetState();
}

class _LinkRequestSheetState extends State<_LinkRequestSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChildProfileBloc, ChildProfileState>(
      builder: (context, state) {
        final loaded = state is ChildProfileLoaded ? state : null;
        final isLoading = loaded?.actionStatus == ActionStatus.inProgress;
        final errorText =
            loaded?.actionStatus == ActionStatus.error
                ? loaded?.actionMessage
                : null;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.lg,
            AppSpacing.screenMargin,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderInactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Link a Therapist', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the email address the therapist used to register.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textPlaceholder),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: "Therapist's email address",
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                errorText: errorText,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPrimaryButton(
                label: 'Send Request',
                isLoading: isLoading,
                onPressed: isLoading
                    ? null
                    : () {
                        final email = _controller.text.trim();
                        if (email.isEmpty) return;
                        context.read<ChildProfileBloc>().add(
                              LinkRequestSubmitted(therapistEmail: email),
                            );
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Request sent dialog ──────────────────────────────────────────────────────

class _RequestSentDialog extends StatelessWidget {
  const _RequestSentDialog({
    required this.therapistEmail,
    required this.onDone,
  });
  final String therapistEmail;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.secondary20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.secondary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Request Sent',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A link request has been sent to $therapistEmail. '
              'Once they accept, they\'ll appear as your child\'s therapist.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textPlaceholder),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                ),
                child: Text(
                  'Done',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

int _age(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

String _formatDate(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
