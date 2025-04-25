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
  final String? cancelledBy;
  final String? cancellationReason;

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
    this.cancelledBy,
    this.cancellationReason,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] ?? '',
      doctorId: json['doctorId'] is Map
          ? json['doctorId']['_id']
          : json['doctorId'] ?? '',
      patientId: json['patientId'] is Map
          ? json['patientId']['_id']
          : json['patientId'] ?? '',
      appointmentDate: json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime'].toString()) ?? DateTime.now()
          : (json['appointmentDate'] != null
              ? DateTime.tryParse(json['appointmentDate'].toString()) ??
                  DateTime.now()
              : DateTime.now()),
      timeSlot: json['timeSlot'] ?? '',
      reason: json['reasonForVisit'] ?? json['reason'] ?? '',
      amount: json['amount'] != null
          ? (json['amount'] is num ? json['amount'].toDouble() : 0.0)
          : 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      doctorDetails:
          json['doctorId'] is Map ? json['doctorId'] : json['doctorDetails'],
      patientDetails:
          json['patientId'] is Map ? json['patientId'] : json['patientDetails'],
      review: json['review'],
      medicalRecord: json['medicalRecord'],
      paymentId: json['paymentId'],
      isNotified: json['isNotified'] ?? false,
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
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
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
    };
  }

  String get formattedAppointmentDate {
    return DateFormat('MMM dd, yyyy').format(appointmentDate);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    // Check if this appointment is cancelled
    if (status.toLowerCase() == 'cancelled' || cancelledBy != null) {
      return false;
    }
    return appointmentDate.isAfter(now) &&
        (status.toLowerCase() == 'pending' ||
            status.toLowerCase() == 'confirmed' ||
            status.toLowerCase() == 'pending_payment'); // Add this new status
  }

  bool get isPast {
    final now = DateTime.now();
    // Consider cancelled appointments as past
    if (status.toLowerCase() == 'cancelled' || cancelledBy != null) {
      return true;
    }
    return appointmentDate.isBefore(now) ||
        (status.toLowerCase() == 'completed' ||
            status.toLowerCase() == 'no-show');
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return Colors.orange; // Or another distinct color
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'no-show':
      case 'no_show': // Handle both formats
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }
}
