import 'package:autilog/core/constants/routes.dart';
import 'package:autilog/core/theme/app_colors.dart';
import 'package:autilog/core/theme/app_spacing.dart';
import 'package:autilog/core/theme/app_text_styles.dart';
import 'package:autilog/shared/widgets/app_primary_button.dart';
import 'package:autilog/shared/widgets/app_snackbar.dart';
import 'package:autilog/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final String? role;

  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;

  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    return null;
  }

  void _login() {
    if (_selectedRole == null) {
      AppSnackbar.showError(context, 'Please select a role');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == 'parent') {
      context.go(Routes.parentHome);
    } else {
      context.go(Routes.therapistHome);
    }
  }

  void _register() {
    if (_selectedRole == null) {
      AppSnackbar.showError(context, 'Please select a role');
      return;
    }

    if (_selectedRole == 'parent') {
      context.go(Routes.registerParent);
    } else {
      context.go(Routes.registerTherapist);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 22,
                  left: 24,
                  right: 24,
                  bottom: 40,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5861F),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.accessibility_new,
                          color: Colors.white,
                          size: 22,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          'AutiLog',
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Welcome back',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              /// FORM
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email',
                        controller: _emailController,
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: 24),

                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        validator: _validatePassword,
                        obscureText: !_showPassword,
                      ),

                      const SizedBox(height: 10),

                      /// SHOW PASSWORD
                      Row(
                        children: [
                          Checkbox(
                            value: _showPassword,
                            activeColor: const Color(0xFFF5861F),
                            onChanged: (value) {
                              setState(() {
                                _showPassword = value ?? false;
                              });
                            },
                          ),

                          Text(
                            'show password',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// LOGIN
                      SizedBox(
                        width: 180,
                        child: AppPrimaryButton(
                          label: 'LOGIN',
                          isLoading: _isLoading,
                          onPressed: _login,
                          borderRadius: 8,
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// REGISTER
                      SizedBox(
                        width: 180,
                        height: 42,
                        child: OutlinedButton(
                          onPressed: _register,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFF5861F),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'REGISTER',
                            style: TextStyle(
                              color: Color(0xFFF5861F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot password?',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// ROLE BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedRole = 'parent';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 4,
                                  backgroundColor: _selectedRole == 'parent'
                                      ? const Color(0xFFF5861F)
                                      : Colors.white,
                                  foregroundColor: _selectedRole == 'parent'
                                      ? Colors.white
                                      : const Color(0xFFF5861F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: Color(0xFFF5861F),
                                    ),
                                  ),
                                ),
                                child: const Text('PARENT'),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedRole = 'therapist';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 4,
                                  backgroundColor: _selectedRole == 'therapist'
                                      ? const Color(0xFFF5861F)
                                      : Colors.white,
                                  foregroundColor: _selectedRole == 'therapist'
                                      ? Colors.white
                                      : const Color(0xFFF5861F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: Color(0xFFF5861F),
                                    ),
                                  ),
                                ),
                                child: const Text('THERAPIST'),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          '© HELP &FEEDBACK',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.black,
                            fontSize: 11,
                          ),
                        ),
                      ),
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
