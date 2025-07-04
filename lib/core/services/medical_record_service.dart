// ignore_for_file: avoid_print

import 'base_api_service.dart';

class MedicalRecordService extends BaseApiService {
  // Get all medical records for a patient (patient view)
  Future<dynamic> getPatientMedicalRecords() async {
    try {
      // Get the user's own ID for "me" endpoint
      // The backend route expects /patient/:patientId, not /patient/me
      final profileResponse = await get('/profile');
      final String patientId = profileResponse['user']['_id'];

      // Now use the proper endpoint with the patient's ID
      final response = await get('/medical-records/patient/$patientId');
      return response;
    } catch (e) {
      print("Error fetching patient medical records: $e");
      rethrow;
    }
  }

  // Get medical records for a specific patient (doctor view)
  Future<dynamic> getPatientMedicalRecordsById(String patientId) async {
    try {
      final response = await get('/medical-records/patient/$patientId');
      return response;
    } catch (e) {
      print("Error fetching patient medical records by ID: $e");
      rethrow;
    }
  }

  // Create a new medical record
  Future<Map<String, dynamic>> createMedicalRecord({
    required String appointmentId,
    required String diagnosis,
    required String notes,
    List<Map<String, dynamic>>? prescriptions,
    List<Map<String, dynamic>>? testResults,
    DateTime? nextVisitDate,
  }) async {
    try {
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

      print(
          "Creating medical record for appointment $appointmentId with data: $data");

      final response =
          await post('/medical-records/$appointmentId', data: data);
      return response;
    } catch (e) {
      print("Error creating medical record: $e");
      rethrow;
    }
  }

  // Get a specific medical record
  Future<Map<String, dynamic>> getMedicalRecord(String recordId) async {
    try {
      final response = await get('/medical-records/record/$recordId');
      return response;
    } catch (e) {
      print("Error fetching medical record: $e");
      rethrow;
    }
  }

  // Update an existing medical record
  Future<Map<String, dynamic>> updateMedicalRecord({
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Remove the duplicate /api prefix
      final response =
          await put('/medical-records/record/$recordId', data: data);
      return response;
    } catch (e) {
      print("Error updating medical record: $e");
      rethrow;
    }
  }

  // Generate PDF for a medical record
  Future<String> generatePdf(String recordId) async {
    try {
      // Remove the duplicate /api prefix
      final response = await get('/medical-records/record/$recordId/pdf');
      if (response['success'] && response['url'] != null) {
        return response['url'];
      }
      throw Exception('Failed to generate PDF');
    } catch (e) {
      print("Error generating PDF: $e");
      rethrow;
    }
  }

  // Add attachments to a medical record
  Future<Map<String, dynamic>> addAttachments(
      String recordId, List<dynamic> files) async {
    try {
      final formData = {
        'files': files,
      };

      // Remove the duplicate /api prefix
      final response = await post(
        '/medical-records/record/$recordId/attachments',
        data: formData,
      );

      return response;
    } catch (e) {
      print("Error adding attachments: $e");
      rethrow;
    }
  }

  // Delete an attachment
  Future<Map<String, dynamic>> deleteAttachment(
      String recordId, String attachmentId) async {
    try {
      // Remove the duplicate /api prefix
      final response = await delete(
          '/medical-records/record/$recordId/attachments/$attachmentId', queryParams: {});
      return response;
    } catch (e) {
      print("Error deleting attachment: $e");
      rethrow;
    }
  }

  // Get medical record statistics (for doctor dashboard)
  Future<Map<String, dynamic>> getMedicalRecordStats() async {
    try {
      // Remove the duplicate /api prefix
      final response = await get('/medical-records/stats');
      return response;
    } catch (e) {
      print("Error fetching medical record stats: $e");
      rethrow;
    }
  }
}
