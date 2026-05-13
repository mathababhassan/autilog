import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.enabled = true,
    this.inputFormatters,
    super.key,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  late TextEditingController _controller;
  late bool _obscure;
  bool _ownsController = false;

  bool get _isFocused => _focusNode.hasFocus;
  bool get _hasValue => _controller.text.isNotEmpty;
  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  void _onFocusChange() => setState(() {});
  void _onControllerChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = FocusNode()..addListener(_onFocusChange);
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  OutlineInputBorder get _enabledBorder => _hasValue
      ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: BorderSide.none,
        )
      : OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.borderInactive),
        );

  static final OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
    borderSide: const BorderSide(color: AppColors.primary, width: 2),
  );

  static final OutlineInputBorder _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
    borderSide: const BorderSide(color: AppColors.error, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    final fillColor =
        _isFocused || !_hasValue ? AppColors.surfaceDefault : AppColors.inputFill;

    final floatingLabelColor = _hasError
        ? AppColors.error
        : _isFocused
            ? AppColors.primary
            : AppColors.textPlaceholder;

    final valueStyle = !_isFocused && _hasValue
        ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
        : AppTextStyles.body;

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      validator: widget.validator,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      inputFormatters: widget.inputFormatters,
      style: valueStyle,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPlaceholder,
        ),
        floatingLabelStyle: AppTextStyles.body.copyWith(
          fontSize: 16,
          color: floatingLabelColor,
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        filled: true,
        fillColor: fillColor,
        enabledBorder: _enabledBorder,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        suffixIcon: widget.obscureText && _hasValue
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textDisabled,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
