import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';

class AppointmentStatusBadge extends StatelessWidget {
  final String status;
  
  const AppointmentStatusBadge({
    super.key,
    required this.status,
  });
  
  @override
  Widget build(BuildContext context) {
    Color statusColor;
    
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'confirmed':
        statusColor = AppColors.primary;
        break;
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      case 'no-show':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}