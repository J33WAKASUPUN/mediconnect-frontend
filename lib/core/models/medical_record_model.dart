import 'package:intl/intl.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String notes;
  final String diagnosis;
  final List<Prescription> prescriptions;
  final List<TestResult> testResults;
  final List<Attachment> attachments;
  final DateTime? nextVisitDate;
  final String status; // 'draft' or 'final'
  final Map<String, dynamic>? doctorDetails;
  final Map<String, dynamic>? patientDetails;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.createdAt,
    this.updatedAt,
    required this.notes,
    required this.diagnosis,
    required this.prescriptions,
    required this.testResults,
    required this.attachments,
    this.nextVisitDate,
    required this.status,
    this.doctorDetails,
    this.patientDetails,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    // Handle prescriptions
    List<Prescription> prescriptions = [];
    if (json['prescriptions'] != null && json['prescriptions'] is List) {
      prescriptions = (json['prescriptions'] as List)
          .map((item) => Prescription.fromJson(item))
          .toList();
    }

    // Handle test results
    List<TestResult> testResults = [];
    if (json['testResults'] != null && json['testResults'] is List) {
      testResults = (json['testResults'] as List)
          .map((item) => TestResult.fromJson(item))
          .toList();
    }

    // Handle attachments
    List<Attachment> attachments = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      attachments = (json['attachments'] as List)
          .map((item) => Attachment.fromJson(item))
          .toList();
    }

    return MedicalRecord(
      id: json['_id'] ?? '',
      patientId: json['patientId'] is Map ? json['patientId']['_id'] : json['patientId'] ?? '',
      doctorId: json['doctorId'] is Map ? json['doctorId']['_id'] : json['doctorId'] ?? '',
      appointmentId: json['appointmentId'] is Map ? json['appointmentId']['_id'] : json['appointmentId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      notes: json['notes'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      prescriptions: prescriptions,
      testResults: testResults,
      attachments: attachments,
      nextVisitDate: json['nextVisitDate'] != null
          ? DateTime.tryParse(json['nextVisitDate'].toString())
          : null,
      status: json['status'] ?? 'draft',
      doctorDetails: json['doctorId'] is Map ? json['doctorId'] : null,
      patientDetails: json['patientId'] is Map ? json['patientId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'notes': notes,
      'diagnosis': diagnosis,
      'prescriptions': prescriptions.map((p) => p.toJson()).toList(),
      'testResults': testResults.map((t) => t.toJson()).toList(),
      'nextVisitDate': nextVisitDate?.toIso8601String(),
      'status': status,
    };
  }

  String get formattedCreatedAt => DateFormat('MMM dd, yyyy').format(createdAt);
  
  String get doctorName {
    if (doctorDetails != null) {
      return 'Dr. ${doctorDetails!['firstName']} ${doctorDetails!['lastName']}';
    }
    return 'Doctor';
  }
  
  String get patientName {
    if (patientDetails != null) {
      return '${patientDetails!['firstName']} ${patientDetails!['lastName']}';
    }
    return 'Patient';
  }
  
  String get doctorSpecialty {
    return doctorDetails?['doctorProfile']?['specialization'] ?? '';
  }
  
  bool get hasPrescriptions => prescriptions.isNotEmpty;
  bool get hasTestResults => testResults.isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;
}

class Prescription {
  final String medicine;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  Prescription({
    required this.medicine,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      medicine: json['medicine'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicine,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}

class TestResult {
  final String testName;
  final String result;
  final String? normalRange;
  final String? remarks;
  final DateTime date;

  TestResult({
    required this.testName,
    required this.result,
    this.normalRange,
    this.remarks,
    required this.date,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testName: json['testName'] ?? '',
      result: json['result'] ?? '',
      normalRange: json['normalRange'],
      remarks: json['remarks'],
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'result': result,
      'normalRange': normalRange,
      'remarks': remarks,
      'date': date.toIso8601String(),
    };
  }
}

class Attachment {
  final String fileName;
  final String fileType;
  final String fileUrl;
  final DateTime uploadedAt;

  Attachment({
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}