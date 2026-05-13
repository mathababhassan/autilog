import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/routes.dart';

class ChildOnboardingScreen extends StatelessWidget {
  const ChildOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "ONE MORE STEP",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Let's set up your child's profile\nso you can start logging today.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Add Child Profile Button
           SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton(
    onPressed: () => context.go(Routes.childRegistration),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF8A00),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: const Text(
      "ADD YOUR CHILD'S PROFILE",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
),

            const SizedBox(height: 20),

            // Skip Option
            TextButton(
              onPressed: () => context.go('/parentHome'),
              child: const Text(
                "I'll do this later →",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
