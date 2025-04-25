import 'package:flutter/material.dart';
import '../../../core/models/medical_record_model.dart';
import '../../../core/services/api_service.dart';

class MedicalRecordsProvider with ChangeNotifier {
  final ApiService _apiService;
  List<MedicalRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  MedicalRecordsProvider({required ApiService apiService})
      : _apiService = apiService;

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all medical records for the patient
  Future<void> loadMedicalRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final jsonList = await _apiService.getPatientMedicalRecords();
      _records = jsonList.map((json) => MedicalRecord.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new medical record (for doctors)
  Future<bool> createMedicalRecord({
    required String appointmentId,
    required String diagnosis,
    required String symptoms,
    required String treatment,
    required String prescription,
    required List<String> tests,
    required String notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createMedicalRecord(
        appointmentId: appointmentId,
        diagnosis: diagnosis,
        symptoms: symptoms,
        treatment: treatment,
        prescription: prescription,
        tests: tests,
        notes: notes,
      );

      _isLoading = false;

      if (response['success']) {
        // Create notification for the patient
        final medicalRecordData =
            response['record'] ?? response['medicalRecord'];
        if (medicalRecordData != null &&
            medicalRecordData['patientId'] != null) {
          await _apiService.createNotification(
            userId: medicalRecordData['patientId'],
            title: 'New Medical Record',
            message:
                'A new medical record has been created for your appointment',
            type: 'medical_record',
            relatedId: medicalRecordData['_id'],
          );
        }

        await loadMedicalRecords(); // Refresh the list
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create medical record';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get a PDF URL for a medical record
  Future<String?> getMedicalRecordPdf(String recordId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final pdfUrl = await _apiService.getMedicalRecordPdf(recordId);

      _isLoading = false;
      notifyListeners();

      return pdfUrl;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
