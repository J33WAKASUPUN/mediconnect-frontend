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

  // Load all medical records for the current patient (patient view)
  Future<void> loadPatientMedicalRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Loading patient medical records...");
      final response = await _apiService.get('/api/medical-records/patient/me');
      
      if (response['success'] && response['data'] != null) {
        final recordsData = response['data']['records'] as List<dynamic>;
        _records = recordsData.map((json) => MedicalRecord.fromJson(json)).toList();
        print("Loaded ${_records.length} medical records");
      } else {
        print("Failed to load records: ${response['message']}");
        _records = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error loading patient medical records: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load medical records for a specific patient (doctor view)
  Future<void> loadPatientMedicalRecordsById(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Loading medical records for patient $patientId...");
      final response = await _apiService.get('/api/medical-records/patient/$patientId');
      
      if (response['success'] && response['data'] != null) {
        final recordsData = response['data']['records'] as List<dynamic>;
        _records = recordsData.map((json) => MedicalRecord.fromJson(json)).toList();
        print("Loaded ${_records.length} medical records for patient $patientId");
      } else {
        print("Failed to load records: ${response['message']}");
        _records = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error loading patient medical records: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a specific medical record
  Future<MedicalRecord?> getMedicalRecord(String recordId) async {
    try {
      print("Fetching medical record $recordId...");
      final response = await _apiService.get('/api/medical-records/record/$recordId');
      
      if (response['success'] && response['data'] != null) {
        return MedicalRecord.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      print("Error fetching medical record: $e");
      return null;
    }
  }

  // Create a new medical record
  Future<bool> createMedicalRecord({
    required String appointmentId,
    required String diagnosis,
    required String notes,
    List<Map<String, dynamic>>? prescriptions,
    List<Map<String, dynamic>>? testResults,
    DateTime? nextVisitDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final Map<String, dynamic> data = {
        'diagnosis': diagnosis,
        'notes': notes,
      };
      
      if (prescriptions != null && prescriptions.isNotEmpty) {
        data['prescriptions'] = prescriptions;
      }
      
      if (testResults != null && testResults.isNotEmpty) {
        data['testResults'] = testResults;
      }
      
      if (nextVisitDate != null) {
        data['nextVisitDate'] = nextVisitDate.toIso8601String();
      }
      
      print("Creating medical record for appointment $appointmentId");
      final response = await _apiService.post('/api/medical-records/$appointmentId', data: data);
      
      if (response['success']) {
        // Send notification to patient
        if (response['data'] != null) {
          final medicalRecord = response['data'];
          String? patientId;
          
          if (medicalRecord['patientId'] is Map) {
            patientId = medicalRecord['patientId']['_id'];
          } else {
            patientId = medicalRecord['patientId'];
          }
          
          if (patientId != null) {
            await _apiService.createNotification(
              userId: patientId,
              title: 'New Medical Record',
              message: 'A new medical record has been created for your appointment',
              type: 'medical_record',
              relatedId: medicalRecord['_id'],
            );
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create medical record';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("Error creating medical record: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Generate PDF for a medical record
  Future<String?> generatePdf(String recordId) async {
    try {
      final response = await _apiService.get('/api/medical-records/record/$recordId/pdf?download=true');
      
      if (response['success'] && response['url'] != null) {
        return response['url'];
      }
      
      return null;
    } catch (e) {
      print("Error generating PDF: $e");
      return null;
    }
  }
}