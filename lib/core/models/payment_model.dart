// lib/core/models/payment_model.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Payment {
  final String id;
  final String appointmentId;
  final double amount;
  final String currency;
  final String status; // PENDING, PROCESSING, COMPLETED, FAILED, REFUNDED, REFUND_FAILED
  final String? paypalOrderId;
  final String? payerId;
  final Map<String, dynamic>? transactionDetails;
  final Map<String, dynamic>? refundDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? appointmentData;
  final Map<String, dynamic>? patientData;
  final Map<String, dynamic>? doctorData;

  Payment({
    required this.id,
    required this.appointmentId,
    required this.amount,
    this.currency = 'RS.',
    required this.status,
    this.paypalOrderId,
    this.payerId,
    this.transactionDetails,
    this.refundDetails,
    required this.createdAt,
    required this.updatedAt,
    this.appointmentData,
    this.patientData,
    this.doctorData,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    // Extract appointment, patient and doctor data if available
    Map<String, dynamic>? appointmentData;
    Map<String, dynamic>? patientData;
    Map<String, dynamic>? doctorData;
    
    if (json['appointmentId'] is Map) {
      appointmentData = Map<String, dynamic>.from(json['appointmentId']);
      
      if (appointmentData.containsKey('patientId') && appointmentData['patientId'] is Map) {
        patientData = Map<String, dynamic>.from(appointmentData['patientId']);
      }
      
      if (appointmentData.containsKey('doctorId') && appointmentData['doctorId'] is Map) {
        doctorData = Map<String, dynamic>.from(appointmentData['doctorId']);
      }
    }

    return Payment(
      id: json['_id'] ?? '',
      appointmentId: json['appointmentId'] is Map 
          ? json['appointmentId']['_id'] 
          : json['appointmentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'RS.',
      status: json['status'] ?? 'PENDING',
      paypalOrderId: json['paypalOrderId'],
      payerId: json['payerId'],
      transactionDetails: json['transactionDetails'] != null 
          ? Map<String, dynamic>.from(json['transactionDetails'])
          : null,
      refundDetails: json['refundDetails'] != null 
          ? Map<String, dynamic>.from(json['refundDetails'])
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      appointmentData: appointmentData,
      patientData: patientData,
      doctorData: doctorData,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'appointmentId': appointmentId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paypalOrderId': paypalOrderId,
      'payerId': payerId,
      'transactionDetails': transactionDetails,
      'refundDetails': refundDetails,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt);
  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
  
  String get statusText {
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'PROCESSING': return 'Processing';
      case 'COMPLETED': return 'Completed';
      case 'FAILED': return 'Failed';
      case 'REFUNDED': return 'Refunded';
      case 'REFUND_FAILED': return 'Refund Failed';
      default: return 'Pending';
    }
  }
  
  Color get statusColor {
    switch (status) {
      case 'COMPLETED': return Colors.green;
      case 'PROCESSING': return Colors.blue;
      case 'PENDING': return Colors.orange;
      case 'FAILED': return Colors.red;
      case 'REFUNDED': return Colors.purple;
      case 'REFUND_FAILED': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  bool get isSuccessful => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isRefunded => status == 'REFUNDED';
  
  String get doctorName {
    if (doctorData != null) {
      return 'Dr. ${doctorData!['firstName'] ?? ''} ${doctorData!['lastName'] ?? ''}';
    } else if (appointmentData != null && appointmentData!['doctorName'] != null) {
      return appointmentData!['doctorName'];
    }
    return 'Doctor';
  }
  
  String get patientName {
    if (patientData != null) {
      return '${patientData!['firstName'] ?? ''} ${patientData!['lastName'] ?? ''}';
    } else if (appointmentData != null && appointmentData!['patientName'] != null) {
      return appointmentData!['patientName'];
    }
    return 'Patient';
  }
  
  DateTime? get appointmentDate {
    if (appointmentData != null && appointmentData!['dateTime'] != null) {
      return DateTime.tryParse(appointmentData!['dateTime']);
    }
    return null;
  }
  
  String get appointmentDateFormatted {
    final date = appointmentDate;
    if (date != null) {
      return DateFormat('MMM dd, yyyy').format(date);
    }
    return 'N/A';
  }
  
  String get receiptUrl {
    // Generate receipt URL based on payment ID
    return '/api/payments/$id/receipt';
  }
}