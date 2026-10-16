import 'package:flutter/material.dart';

/// Reusable, theme-aware text field used by every form in the app.
///
/// Wraps [TextFormField] with a label, an optional leading icon and, when
/// [obscureText] is set, a show/hide password toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
    this.autofillHints,
    this.autofocus = false,
  });

  /// Text controller owned by the parent form.
  final TextEditingController controller;

  /// Floating label.
  final String label;

  /// Optional helper hint.
  final String? hint;

  /// Optional leading icon.
  final IconData? icon;

  /// When `true`, the value is masked and a visibility toggle is shown.
  final bool obscureText;

  /// Keyboard type (e.g. `TextInputType.emailAddress`).
  final TextInputType? keyboardType;

  /// Action button shown on the soft keyboard.
  final TextInputAction? textInputAction;

  /// Optional validator (see `Validators`).
  final String? Function(String?)? validator;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field accepts input.
  final bool enabled;

  /// Autofill hints for the platform's password managers.
  final Iterable<String>? autofillHints;

  /// Requests focus as soon as the field is mounted.
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscured ? 'Show password' : 'Hide password',
              )
            : null,
      ),
    );
  }
}
