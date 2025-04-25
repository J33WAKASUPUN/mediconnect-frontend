import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/shared/constants/colors.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // appointment_created, appointment_confirmed, etc.
  final String? relatedId;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    print("Processing notification JSON: ${json['_id']}");

    // Extract the type - default to 'system' if not found
    String notificationType = json['type'] ?? 'system';

    // Map from backend types to our app types if needed
    if (notificationType.contains('appointment')) {
      notificationType = 'appointment';
    } else if (notificationType.contains('payment')) {
      notificationType = 'payment';
    }

    return AppNotification(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: notificationType,
      relatedId:
          json['appointmentId'] ?? json['paymentId'] ?? json['relatedId'],
      timestamp:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(timestamp);

  IconData get icon {
    // More specific matching based on type prefixes
    if (type.contains('appointment')) {
      return Icons.calendar_today;
    } else if (type.contains('payment') || type.contains('refund')) {
      return Icons.payment;
    } else if (type.contains('medical_record')) {
      return Icons.description;
    } else {
      return Icons.notifications;
    }
  }

  Color get color {
    // More specific matching based on type and status
    if (type.contains('created') || type.contains('pending')) {
      return AppColors.warning; // Orange/yellow for pending states
    } else if (type.contains('confirmed') || type.contains('completed')) {
      return AppColors.success; // Green for success states
    } else if (type.contains('cancelled') || type.contains('failed')) {
      return AppColors.error; // Red for error/cancelled states
    } else if (type.contains('medical_record')) {
      return AppColors.info;
    } else {
      return AppColors.primary; // Default color
    }
  }
}
