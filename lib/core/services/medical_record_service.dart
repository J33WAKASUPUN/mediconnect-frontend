import 'base_api_service.dart';
import '../../config/api_endpoints.dart';

class MedicalRecordService extends BaseApiService {
  // Get all medical records for a patient
  Future<List<Map<String, dynamic>>> getPatientMedicalRecords() async {
    try {
      final response = await get(ApiEndpoints.patientMedicalRecords);
      if (response['success'] && response['records'] is List) {
        return List<Map<String, dynamic>>.from(response['records']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Create a new medical record
  Future<Map<String, dynamic>> createMedicalRecord({
    required String appointmentId,
    required String diagnosis,
    required String symptoms,
    required String treatment,
    required String prescription,
    required List<String> tests,
    required String notes,
  }) async {
    try {
      final response = await post(
        '${ApiEndpoints.appointments}/$appointmentId/medical-record',
        data: {
          'diagnosis': diagnosis,
          'symptoms': symptoms,
          'treatment': treatment,
          'prescription': prescription,
          'tests': tests,
          'notes': notes,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get a single medical record
  Future<Map<String, dynamic>> getMedicalRecord(String recordId) async {
    try {
      final response = await get('${ApiEndpoints.medicalRecords}/$recordId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get the PDF of a medical record
  Future<String?> getMedicalRecordPdf(String recordId) async {
    try {
      final response =
          await get('${ApiEndpoints.medicalRecords}/$recordId/pdf');
      if (response['success'] && response['pdfUrl'] != null) {
        return response['pdfUrl'];
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
