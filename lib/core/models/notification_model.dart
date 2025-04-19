import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/shared/constants/colors.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // appointment, payment, medical_record, system
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
    return AppNotification(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      relatedId: json['relatedId'],
      timestamp: DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
  
  String get formattedDate => DateFormat('MMM dd, yyyy').format(timestamp);
  
  IconData get icon {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'medical_record':
        return Icons.description;
      case 'system':
      default:
        return Icons.notifications;
    }
  }
  
  Color get color {
    switch (type) {
      case 'appointment':
        return AppColors.primary;
      case 'payment':
        return AppColors.success;
      case 'medical_record':
        return AppColors.info;
      case 'system':
      default:
        return AppColors.warning;
    }
  }
}