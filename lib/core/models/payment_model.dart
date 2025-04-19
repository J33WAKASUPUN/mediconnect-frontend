import 'package:intl/intl.dart';

class Payment {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final double amount;
  final String status; // pending, completed, failed
  final String paymentMethod;
  final DateTime timestamp;
  final String? transactionId;
  final String? receiptUrl;

  Payment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.timestamp,
    this.transactionId,
    this.receiptUrl,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now(),
      transactionId: json['transactionId'],
      receiptUrl: json['receiptUrl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp.toIso8601String(),
      'transactionId': transactionId,
      'receiptUrl': receiptUrl,
    };
  }
  
  String get formattedDate => DateFormat('MMM dd, yyyy').format(timestamp);
  String get formattedAmount => 'Rs. ${amount.toStringAsFixed(2)}';
}