import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/shared/constants/colors.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime appointmentDate;
  final String timeSlot;
  final String reason;
  final double amount;
  final String status; // pending, confirmed, completed, cancelled, no-show
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? doctorDetails;
  final Map<String, dynamic>? patientDetails;
  final Map<String, dynamic>? review;
  final Map<String, dynamic>? medicalRecord;
  final String? paymentId;
  final bool isNotified;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.reason,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.doctorDetails,
    this.patientDetails,
    this.review,
    this.medicalRecord,
    this.paymentId,
    this.isNotified = false,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.tryParse(json['appointmentDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeSlot: json['timeSlot'] ?? '',
      reason: json['reason'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      doctorDetails: json['doctorDetails'],
      patientDetails: json['patientDetails'],
      review: json['review'],
      medicalRecord: json['medicalRecord'],
      paymentId: json['paymentId'],
      isNotified: json['isNotified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'appointmentDate': DateFormat('yyyy-MM-dd').format(appointmentDate),
      'timeSlot': timeSlot,
      'reason': reason,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'review': review,
      'medicalRecord': medicalRecord,
      'paymentId': paymentId,
      'isNotified': isNotified,
    };
  }

  String get formattedAppointmentDate {
    return DateFormat('MMM dd, yyyy').format(appointmentDate);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return appointmentDate.isAfter(now) && 
           (status == 'pending' || status == 'confirmed');
  }

  bool get isPast {
    final now = DateTime.now();
    return appointmentDate.isBefore(now) || 
           (status == 'completed' || status == 'cancelled' || status == 'no-show');
  }
  
  bool get needsPayment {
    return status == 'confirmed' && paymentId == null;
  }
  
  bool get canBeReviewed {
    return status == 'completed' && review == null;
  }
  
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'no-show':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }
}