import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../features/auth/bloc/child_registration_bloc.dart';
import '../../../../../features/auth/bloc/child_registration_event.dart';
import '../../../../../features/auth/bloc/child_registration_state.dart';
import '../../../../../features/auth/data/auth_repository.dart';
import '../../../../../core/constants/routes.dart';


import 'package:formz/formz.dart';

class ChildRegistrationScreen extends StatelessWidget {
  /// Set to true when navigated from the parent profile (not registration flow).
  /// Hides the "I'll do this later" skip button.
  final bool fromProfile;
  const ChildRegistrationScreen({super.key, this.fromProfile = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChildRegistrationBloc(
        authRepository: ctx.read<AuthRepository>(),
      ),
      child: BlocListener<ChildRegistrationBloc, ChildRegistrationState>(
        listener: (context, state) {
          if (state.status == FormzSubmissionStatus.success) {
            context.go(Routes.parentHome);
          }
          if (state.status == FormzSubmissionStatus.failure &&
              state.serverError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.serverError!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _ChildRegistrationView(fromProfile: fromProfile),
      ),
    );
  }
}

class _ChildRegistrationView extends StatefulWidget {
  final bool fromProfile;
  const _ChildRegistrationView({this.fromProfile = false});

  @override
  State<_ChildRegistrationView> createState() => _ChildRegistrationViewState();
}

class _ChildRegistrationViewState extends State<_ChildRegistrationView> {
  final _nameController = TextEditingController();
  DateTime? _selectedDob;

  static const _diagnosisOptions = [
    'ASD Level 1 – Requiring support',
    'ASD Level 2 – Requiring substantial support',
    'ASD Level 3 – Requiring very substantial support',
  ];

  static const _valueMap = {
    'ASD Level 1 – Requiring support': 'Level 1',
    'ASD Level 2 – Requiring substantial support': 'Level 2',
    'ASD Level 3 – Requiring very substantial support': 'Level 3',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDob(BuildContext context) async {
    final bloc = context.read<ChildRegistrationBloc>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 5),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: "Select Child's Date of Birth",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8A00),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
      // Calculate age from dob and emit
      final age = now.year -
          picked.year -
          (now.month < picked.month ||
                  (now.month == picked.month && now.day < picked.day)
              ? 1
              : 0);
      bloc.add(ChildAgeChanged(age.toString()));
      bloc.add(ChildDobChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChildRegistrationBloc, ChildRegistrationState>(
      builder: (context, state) {
        final bloc = context.read<ChildRegistrationBloc>();
        final isLoading = state.status == FormzSubmissionStatus.inProgress;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(context),

              // ── Form ────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Child's Profile",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "This helps your therapist understand your child better.",
                        style: TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 28),

                      // Child's Name
                      _buildLabel("Child's Full Name"),
                      _buildTextField(
                        controller: _nameController,
                        hint: "e.g. Adam Hassan",
                        errorText: state.nameError,
                        onChanged: (v) => bloc.add(ChildNameChanged(v)),
                      ),
                      const SizedBox(height: 20),

                      // Date of Birth
                      _buildLabel("Date of Birth"),
                      _buildDobPicker(context, state),
                      if (state.ageError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          state.ageError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Gender
                      _buildLabel("Gender"),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildRadioButton(
                              label: "Male",
                              value: "male",
                              groupValue: state.gender,
                              onChanged: (v) =>
                                  bloc.add(ChildGenderChanged(v!))),
                          _buildRadioButton(
                              label: "Female",
                              value: "female",
                              groupValue: state.gender,
                              onChanged: (v) =>
                                  bloc.add(ChildGenderChanged(v!))),
                          _buildRadioButton(
                              label: "Prefer not to say",
                              value: "other",
                              groupValue: state.gender,
                              onChanged: (v) =>
                                  bloc.add(ChildGenderChanged(v!))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Diagnosis / ASD Severity
                      _buildLabel("Diagnosis Type"),
                      _buildDiagnosisDropdown(context, state, bloc),
                      if (state.asdSeverityError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          state.asdSeverityError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Therapist Email (optional)
                      _buildLabel("Therapist Email (optional)"),
                      _buildTextField(
                        hint: "therapist@clinic.com",
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) =>
                            bloc.add(ChildTherapistEmailChanged(v)),
                      ),
                      const SizedBox(height: 36),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => bloc
                                  .add(const ChildRegistrationSubmitted()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "SAVE CHILD PROFILE",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Skip — only shown during registration, not when opened from profile
                      if (!widget.fromProfile)
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/parentHome'),
                            child: const Text(
                              "I'll do this later →",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 14),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFF8A00),
        borderRadius:
            BorderRadius.only(bottomLeft: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AutiLog",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            "Add Child Profile",
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Tell us about your child so we can personalise the experience.",
            style: TextStyle(
                color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hint,
    required Function(String) onChanged,
    String? errorText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        errorText: errorText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              const BorderSide(color: Color(0xFFFF8A00), width: 2),
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

  Widget _buildDobPicker(
      BuildContext context, ChildRegistrationState state) {
    final dob = _selectedDob;
    final display = dob != null
        ? "${dob.day.toString().padLeft(2, '0')}/"
            "${dob.month.toString().padLeft(2, '0')}/"
            "${dob.year}"
        : "DD / MM / YYYY";

    return GestureDetector(
      onTap: () => _pickDob(context),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: state.ageError != null ? Colors.red : Colors.black26,
            width: state.ageError != null ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              display,
              style: TextStyle(
                fontSize: 16,
                color: dob != null ? Colors.black87 : Colors.black26,
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                color: Color(0xFFFF8A00), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisDropdown(BuildContext context,
      ChildRegistrationState state, ChildRegistrationBloc bloc) {
    final displayValue = state.asdSeverity == 'Level 1'
        ? _diagnosisOptions[0]
        : state.asdSeverity == 'Level 2'
            ? _diagnosisOptions[1]
            : state.asdSeverity == 'Level 3'
                ? _diagnosisOptions[2]
                : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              state.asdSeverityError != null ? Colors.red : Colors.black26,
          width: state.asdSeverityError != null ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayValue,
          isExpanded: true,
          hint: const Text(
            "Select diagnosis type",
            style: TextStyle(color: Colors.black26, fontSize: 16),
          ),
          items: _diagnosisOptions
              .map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label,
                        style: const TextStyle(fontSize: 15)),
                  ))
              .toList(),
          onChanged: (label) {
            if (label != null) {
              final value = _valueMap[label]!;
              bloc.add(ChildSeverityChanged(value));
            }
          },
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
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}