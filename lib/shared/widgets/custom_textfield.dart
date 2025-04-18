import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/styles.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue; // Add this
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool readOnly;
  final bool enabled; // Add this
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final bool autofocus; // Add this too for the dialog

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue, // Add this
    this.validator,
    this.isPassword = false,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true, // Add this with default value
    this.onTap,
    this.onChanged,
    this.autofocus = false, // Add this with default value
  }) : assert(controller == null || initialValue == null, 
         "Cannot provide both a controller and an initialValue");

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      validator: widget.validator,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      decoration: AppStyles.inputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null 
            ? Icon(widget.prefixIcon) 
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}