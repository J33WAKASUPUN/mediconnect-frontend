import 'package:intl/intl.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final DateTime date;
  final String diagnosis;
  final String symptoms;
  final String treatment;
  final String prescription;
  final List<String> tests;
  final String notes;
  final Map<String, dynamic>? doctorDetails;
  final String? pdfUrl;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.date,
    required this.diagnosis,
    required this.symptoms,
    required this.treatment,
    required this.prescription,
    required this.tests,
    required this.notes,
    this.doctorDetails,
    this.pdfUrl,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      diagnosis: json['diagnosis'] ?? '',
      symptoms: json['symptoms'] ?? '',
      treatment: json['treatment'] ?? '',
      prescription: json['prescription'] ?? '',
      tests: json['tests'] is List
          ? List<String>.from(json['tests'])
          : [],
      notes: json['notes'] ?? '',
      doctorDetails: json['doctorDetails'],
      pdfUrl: json['pdfUrl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'date': date.toIso8601String(),
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'treatment': treatment,
      'prescription': prescription,
      'tests': tests,
      'notes': notes,
      'pdfUrl': pdfUrl,
    };
  }
  
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  
  String get doctorName {
    if (doctorDetails != null) {
      return 'Dr. ${doctorDetails!['firstName']} ${doctorDetails!['lastName']}';
    }
    return 'Doctor';
  }
  
  String get doctorSpecialty {
    return doctorDetails?['doctorProfile']?['specialization'] ?? '';
  }
}