import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';

import '../../../../../features/auth/bloc/parent_registration_bloc.dart';
import '../../../../../features/auth/data/auth_repository.dart';

import '../../../../../shared/widgets/widgets.dart';

class ParentRegistrationScreen extends StatelessWidget {
  const ParentRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          ParentRegistrationBloc(authRepository: ctx.read<AuthRepository>()),
      child: const _RegistrationView(),
    );
  }
}

class _RegistrationView extends StatefulWidget {
  const _RegistrationView();

  @override
  State<_RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<_RegistrationView> {
  bool _passwordVisible = false;

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
      context.read<ParentRegistrationBloc>().add(
        ParentRegistrationProfilePhotoChanged(picked.path),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParentRegistrationBloc, ParentRegistrationState>(
      listener: (context, state) {
        if (state.status == FormzSubmissionStatus.success) {
          context.go(Routes.childOnboarding);
        }

        if (state.status == FormzSubmissionStatus.failure) {
          AppSnackbar.showError(
            context,
            state.serverError ?? 'Please fix form errors',
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<ParentRegistrationBloc>();

        final isLoading = state.status == FormzSubmissionStatus.inProgress;

        return Scaffold(
          backgroundColor: AppColors.surfaceDefault,
          body: CustomScrollView(
            slivers: [
              /// HEADER
              SliverAppBar(
                pinned: true,
                expandedHeight: 210,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(56),
                        bottomRight: Radius.circular(56),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: 0,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),

                        Positioned(
                          right: 110,
                          top: 10,
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 60,
                            left: 24,
                            right: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(Routes.login);
                                  }
                                },
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),

                              const SizedBox(height: 24),

                              Text(
                                'Register As Parent',
                                style: AppTextStyles.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Register as a parent to get started',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// BODY
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                    vertical: AppSpacing.xl2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Account', style: AppTextStyles.heading1),

                      const SizedBox(height: AppSpacing.xl2),

                      /// PHOTO
                      Center(
                        child: GestureDetector(
                          onTap: () => _pickImage(context),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: AppColors.inputFill,
                            backgroundImage: state.profilePhotoPath != null
                                ? FileImage(File(state.profilePhotoPath!))
                                : null,
                            child: state.profilePhotoPath == null
                                ? const Icon(
                                    Icons.person_outline,
                                    size: 42,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Center(
                        child: Text(
                          'Tap to add photo',
                          style: AppTextStyles.caption,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl2),

                      /// NAME
                      AppTextField(
                        label: 'Full Name',
                        errorText: state.nameError,
                        onChanged: (v) {
                          bloc.add(ParentRegistrationNameChanged(v));
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      /// EMAIL
                      AppTextField(
                        label: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        errorText: state.emailError,
                        onChanged: (v) {
                          bloc.add(ParentRegistrationEmailChanged(v));
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      /// PASSWORD
                      AppTextField(
                        label: 'Password',
                        obscureText: !_passwordVisible,
                        errorText: state.passwordError,
                        onChanged: (v) {
                          bloc.add(ParentRegistrationPasswordChanged(v));
                        },
                      ),

                      Row(
                        children: [
                          Checkbox(
                            value: _passwordVisible,
                            activeColor: AppColors.primary,
                            onChanged: (v) {
                              setState(() {
                                _passwordVisible = v ?? false;
                              });
                            },
                          ),
                          Text('show password', style: AppTextStyles.body),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      /// GENDER
                      Text('Gender', style: AppTextStyles.body),

                      const SizedBox(height: AppSpacing.sm),

                      Wrap(
                        spacing: AppSpacing.lg,
                        children: [
                          _genderOption(
                            label: 'Male',
                            value: 'male',
                            groupValue: state.gender,
                            onChanged: (v) {
                              bloc.add(ParentRegistrationGenderChanged(v!));
                            },
                          ),

                          _genderOption(
                            label: 'Female',
                            value: 'female',
                            groupValue: state.gender,
                            onChanged: (v) {
                              bloc.add(ParentRegistrationGenderChanged(v!));
                            },
                          ),

                          _genderOption(
                            label: 'Prefer not to say',
                            value: 'other',
                            groupValue: state.gender,
                            onChanged: (v) {
                              bloc.add(ParentRegistrationGenderChanged(v!));
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl3),

                      /// BUTTON
                      AppPrimaryButton(
                        label: 'Create Account',
                        borderRadius: AppSpacing.pillRadius,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () {
                                bloc.add(const ParentRegistrationSubmitted());
                              },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      /// TERMS
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: state.termsAccepted,
                            activeColor: AppColors.primary,
                            onChanged: (_) {
                              bloc.add(const ParentRegistrationTermsToggled());
                            },
                          ),

                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: AppTextStyles.caption,
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl2),

                      /// LOGIN
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: AppTextStyles.caption,
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () {
                                    context.go(Routes.login);
                                  },
                                  child: Text(
                                    'Log in',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      Text('© HELP & FEEDBACK', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _genderOption({
    required String label,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
        Text(label, style: AppTextStyles.body),
      ],
    );
  }
}
