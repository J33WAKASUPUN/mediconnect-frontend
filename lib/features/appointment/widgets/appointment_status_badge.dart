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
    String displayText = status.toUpperCase();
    IconData? statusIcon;

    // Map status values to display text and colors
    switch (status.toLowerCase()) {
      case 'pending_payment':
        statusColor = Colors.orange;
        displayText = 'PAYMENT NEEDED';
        statusIcon = Icons.payment;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'confirmed':
        statusColor = AppColors.primary;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'no-show':
      case 'no_show':
        statusColor = Colors.grey;
        displayText = 'NO SHOW';
        statusIcon = Icons.person_off;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}