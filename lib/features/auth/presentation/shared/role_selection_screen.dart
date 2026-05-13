import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl4),

              Text(
                'Register As',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textWhite,
                ),
              ),

              const SizedBox(height: 20),

              /// ✅ THERAPIST → LOGIN WITH ROLE
              _HoverButton(
                label: 'Therapist',
                defaultColor: AppColors.secondary,
                hoverColor: AppColors.secondary.withOpacity(0.75),
                textColor: AppColors.textWhite,
                filled: true,
                onTap: () => context.go('${Routes.login}?role=therapist'),
              ),

              const SizedBox(height: 12),

              /// ✅ PARENT → LOGIN WITH ROLE
              _HoverButton(
                label: 'Parent',
                defaultColor: Colors.transparent,
                hoverColor: AppColors.textWhite.withOpacity(0.15),
                textColor: AppColors.textWhite,
                filled: false,
                onTap: () => context.go('${Routes.login}?role=parent'),
              ),

              const SizedBox(height: 30),

              /// LOGIN LINK (DEFAULT → no role)
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/auth/login'),
                  child: const Text(
                    'Already have account? Login',
                    style: TextStyle(color: Colors.white),
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

class _HoverButton extends StatefulWidget {
  final String label;
  final Color defaultColor;
  final Color hoverColor;
  final Color textColor;
  final bool filled;
  final VoidCallback onTap;

  const _HoverButton({
    required this.label,
    required this.defaultColor,
    required this.hoverColor,
    required this.textColor,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : widget.defaultColor,
            borderRadius: BorderRadius.circular(AppSpacing.xl3),
            border: widget.filled
                ? null
                : Border.all(color: AppColors.textWhite, width: 1.5),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.subtitle.copyWith(
                color: widget.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverLoginLink extends StatefulWidget {
  final VoidCallback onTap;

  const _HoverLoginLink({required this.onTap});

  @override
  State<_HoverLoginLink> createState() => _HoverLoginLinkState();
}

class _HoverLoginLinkState extends State<_HoverLoginLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: AppTextStyles.caption.copyWith(color: AppColors.textWhite),
            children: [
              TextSpan(
                text: 'Login instead',
                style: AppTextStyles.caption.copyWith(
                  color: _hovered ? AppColors.textWhite : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: _hovered
                      ? AppColors.textWhite
                      : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
