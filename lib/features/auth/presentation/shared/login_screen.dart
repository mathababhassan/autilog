import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/constants/routes.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepository = context.read<AuthRepository>();
      final user = await authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user.role == 'therapist') {
        context.go(Routes.therapistHome);
      } else {
        context.go(Routes.parentHome);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Invalid email or password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin,
                  vertical: AppSpacing.xl2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: AppColors.textWhite,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'AutiLog',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl4),
                    Text(
                      'Welcome\nback',
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 40,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Log in to continue',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),

              // Form card
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDefault,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.xl2),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go(Routes.forgotPassword),
                          child: Text(
                            'Forgot password?',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      AppPrimaryButton(
                        label: 'Log In',
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(Routes.roleSelection),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textDisabled,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Register',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}