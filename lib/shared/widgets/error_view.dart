import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import 'custom_button.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? buttonText;
  final IconData? icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.buttonText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: AppStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppStyles.bodyText1.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              CustomButton(
                text: buttonText ?? 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
          ],
        ),
      ),
    );
  }
}