import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../features/auth/bloc/child_registration_bloc.dart';
import '../../../../../features/auth/bloc/child_registration_event.dart';
import '../../../../../features/auth/bloc/child_registration_state.dart';
import '../../../../../features/auth/data/auth_repository.dart';
import 'package:formz/formz.dart';

class ChildRegistrationScreen extends StatelessWidget {
  const ChildRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChildRegistrationBloc(
        authRepository: ctx.read<AuthRepository>(),
      ),
      child: BlocListener<ChildRegistrationBloc, ChildRegistrationState>(
        listener: (context, state) {
          if (state.status == FormzSubmissionStatus.success) {
  context.go('/parentHome');
}
if (state.status == FormzSubmissionStatus.failure && state.serverError != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Error: ${state.serverError}")),
  );
}

        },
        child: const _ChildRegistrationView(),
      ),
    );
  }
}

class _ChildRegistrationView extends StatelessWidget {
  const _ChildRegistrationView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChildRegistrationBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Child Profile"),
        backgroundColor: const Color(0xFFFF8A00),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text("Let's get to know your child",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),
            _buildTextField("Child's Name", (v) => bloc.add(ChildNameChanged(v))),
            const SizedBox(height: 16),
            _buildTextField("Age", (v) => bloc.add(ChildAgeChanged(v))),
            const SizedBox(height: 16),

            const Text("Gender"),
            Row(
              children: [
                _buildRadio("Male", "male", bloc),
                _buildRadio("Female", "female", bloc),
                _buildRadio("Prefer not to say", "other", bloc),
              ],
            ),

            const SizedBox(height: 16),
            const Text("ASD Severity"),
            DropdownButton<String>(
              value: bloc.state.asdSeverity,
              items: const [
                DropdownMenuItem(value: "Level 1", child: Text("Level 1 — Requires some support")),
                DropdownMenuItem(value: "Level 2", child: Text("Level 2 — Requires substantial support")),
                DropdownMenuItem(value: "Level 3", child: Text("Level 3 — Requires very substantial support")),
              ],
              onChanged: (v) => bloc.add(ChildSeverityChanged(v!)),
            ),

            const SizedBox(height: 16),
            _buildTextField("Therapist Email (optional)", (v) => bloc.add(ChildTherapistEmailChanged(v))),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => bloc.add(const ChildRegistrationSubmitted()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("SAVE CHILD PROFILE",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go('/child-step2'),
              child: const Text("+ Add another child"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: onChanged,
    );
  }

  Widget _buildRadio(String label, String value, ChildRegistrationBloc bloc) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: bloc.state.gender,
          onChanged: (v) => bloc.add(ChildGenderChanged(v!)),
        ),
        Text(label),
      ],
    );
  }
}
