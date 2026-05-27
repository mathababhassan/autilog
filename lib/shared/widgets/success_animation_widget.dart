import 'package:flutter/material.dart';

/// A simple success animation widget.
/// You can later replace this with Lottie or Rive animation if you want.
class SuccessAnimationWidget extends StatelessWidget {
  const SuccessAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check_circle,
      color: Colors.green,
      size: 80,
    );
  }
}
