import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isLoading;
  final IconData? icon;
  final double? width; // Add width parameter

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
    this.icon,
    this.width, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // Use the width parameter instead of double.infinity
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? AppColors.surface : AppColors.primary,
          foregroundColor:
              isSecondary ? AppColors.primary : AppColors.textLight,
          side: isSecondary ? const BorderSide(color: AppColors.primary) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.textLight),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min, // Add this
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon),
                      const SizedBox(width: 8),
                    ],
                    Text(text),
                  ],
                ),
        ),
      ),
    );
  }
}
