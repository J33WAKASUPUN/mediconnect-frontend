import 'package:flutter/material.dart';
import '../../shared/constants/colors.dart';

class StyledDrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? trailing;

  const StyledDrawerItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary.withOpacity(0.1);
    final txtColor = textColor ?? AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
      ),
      child: ListTile(
        leading: Icon(icon, color: txtColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: txtColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}