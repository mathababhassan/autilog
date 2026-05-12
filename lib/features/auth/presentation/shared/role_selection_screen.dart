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
              const SizedBox(height: AppSpacing.xl2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.textWhite,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl5),
              Text(
                'Welcome to\nAutiLog',
                style: AppTextStyles.display.copyWith(
                  color: AppColors.textWhite,
                  fontSize: 40,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Let's setup your account and get you ready!",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textWhite,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: AppSpacing.xl4),
              Text(
                'Register As',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _HoverButton(
                label: 'Therapist',
                defaultColor: AppColors.secondary,
                hoverColor: AppColors.secondary.withOpacity(0.75),
                textColor: AppColors.textWhite,
                filled: true,
                onTap: () => context.go('/auth/register/therapist'),
              ),
              const SizedBox(height: AppSpacing.md),
              _HoverButton(
                label: 'Parent',
                defaultColor: Colors.transparent,
                hoverColor: AppColors.textWhite.withOpacity(0.15),
                textColor: AppColors.textWhite,
                filled: false,
                onTap: () => context.go(Routes.registerParent),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Center(
                child: _HoverLoginLink(
                  onTap: () => context.go('/auth/login'),
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
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textWhite,
            ),
            children: [
              TextSpan(
                text: 'Login instead',
                style: AppTextStyles.caption.copyWith(
                  color: _hovered ? AppColors.textWhite : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor:
                      _hovered ? AppColors.textWhite : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}