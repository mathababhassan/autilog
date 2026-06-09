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

class ParentRegistrationScreen extends StatelessWidget {
  const ParentRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ParentRegistrationBloc(
        authRepository: ctx.read<AuthRepository>(),
      ),
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
    final bloc = context.read<ParentRegistrationBloc>();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      bloc.add(ParentRegistrationProfilePhotoChanged(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParentRegistrationBloc, ParentRegistrationState>(
    listener: (context, state) {
  // ✅ SUCCESS
  if (state.status == FormzSubmissionStatus.success) {
    context.go(Routes.childOnboarding); 
  }

  // ❌ FAILURE (THIS WAS MISSING)
  if (state.status == FormzSubmissionStatus.failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.serverError ?? "Please fix form errors"),
        backgroundColor: Colors.red,
      ),
    );
  }
  print("STATUS: ${state.status}");
},
      builder: (context, state) {
        final bloc = context.read<ParentRegistrationBloc>();
        final isLoading = state.status == FormzSubmissionStatus.inProgress;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header from image_d20735.png
                _buildHeader(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        "Create Parent Account",
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Profile Photo Section
                      const Text(
                        "Profile Photo", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage(context),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: const Color(0xFFE0E0E0),
                                backgroundImage: state.profilePhotoPath != null
                                    ? FileImage(File(state.profilePhotoPath!))
                                    : null,
                                child: state.profilePhotoPath == null
                                    ? const Icon(Icons.person_outline, size: 50, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tap to add photo", 
                              style: TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Input Fields
                      _buildLabel("Full Name"),
                      _buildTextField(
                        hint: "Sara Hassan",
                        onChanged: (v) => bloc.add(ParentRegistrationNameChanged(v)),
                        errorText: state.nameError,
                      ),

                      const SizedBox(height: 16),
                      _buildLabel("Email"),
                      _buildTextField(
                        hint: "sara-hassan@email.com",
                        onChanged: (v) => bloc.add(ParentRegistrationEmailChanged(v)),
                        errorText: state.emailError,
                      ),

                      const SizedBox(height: 16),
                      _buildLabel("Password"),
                      _buildTextField(
                        hint: "************",
                        obscureText: !_passwordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible 
                                ? Icons.visibility 
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                        ),
                        onChanged: (v) => bloc.add(ParentRegistrationPasswordChanged(v)),
                        errorText: state.passwordError,
                      ),
                      
                      // Password Strength indicators would go here if defined in state

                      const SizedBox(height: 24),

                      // Gender Section from image_d1f854.png
                      _buildLabel("Gender"),
                      Wrap(
                        spacing: 10,
                        children: [
                          _buildRadioButton(
                            label: "Male",
                            value: "male",
                            groupValue: state.gender,
                            onChanged: (v) => bloc.add(ParentRegistrationGenderChanged(v!)),
                          ),
                          _buildRadioButton(
                            label: "Female",
                            value: "female",
                            groupValue: state.gender,
                            onChanged: (v) => bloc.add(ParentRegistrationGenderChanged(v!)),
                          ),
                          _buildRadioButton(
                            label: "Prefer not to say",
                            value: "other",
                            groupValue: state.gender,
                            onChanged: (v) => bloc.add(ParentRegistrationGenderChanged(v!)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => bloc.add(const ParentRegistrationSubmitted()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Create Account", 
                                  style: TextStyle(
                                    fontSize: 18, 
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms and Conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         SizedBox(
  height: 24,
  width: 24,
  child: Checkbox(
    value: state.termsAccepted,
    // Removed 'termsAccepted:' label here
onChanged: (_) => bloc.add(const ParentRegistrationTermsToggled()),
    activeColor: const Color(0xFFFF8A00),
    side: const BorderSide(color: Colors.grey),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
                                children: [
                                  TextSpan(text: "I agree to the Autilog "),
                                  TextSpan(
                                    text: "Terms of Service",
                                    style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: " and "),
                                  TextSpan(
                                    text: "Privacy Policy",
                                    style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      
                      Center(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.info_outline, size: 16, color: Colors.black54),
                          label: const Text(
                            "HELP & FEEDBACK", 
                            style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFF8A00),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
      ),
      child: Stack(
        children: [
          // Decorative circles from design
          Positioned(
            right: -20, 
            top: 80, 
            child: CircleAvatar(radius: 65, backgroundColor: Colors.white.withOpacity(0.15)),
          ),
          Positioned(
            right: 70, 
            top: 75, 
            child: CircleAvatar(radius: 18, backgroundColor: Colors.white.withOpacity(0.15)),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "AutiLog", 
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.3), 
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.go(Routes.roleSelection),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Register As Parent",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Remove 'const' from here
Text(
  "Let's setup your account and\nget you ready!",
  style: TextStyle(
    color: Colors.white.withOpacity(0.9), // Now this method can be invoked
    fontSize: 15,
  ),
),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        label, 
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required Function(String) onChanged,
    String? errorText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      onChanged: onChanged,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        errorText: errorText,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildRadioButton({
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
          onChanged: onChanged,
          activeColor: const Color(0xFFFF8A00),
          visualDensity: const VisualDensity(horizontal: -4),
        ),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}