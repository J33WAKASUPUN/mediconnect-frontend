import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class RoleToggle extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;

  const RoleToggle({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: [
          _buildRoleOption('patient', 'Patient', Icons.personal_injury),
          _buildRoleOption('doctor', 'Doctor', Icons.medical_services),
        ],
      ),
    );
  }

  Expanded _buildRoleOption(String role, String label, IconData icon) {
    final isSelected = selectedRole == role;
    
    return Expanded(
      child: InkWell(
        onTap: () => onRoleChanged(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textLight : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}