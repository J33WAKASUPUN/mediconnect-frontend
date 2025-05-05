import 'base_api_service.dart';
import '../../config/api_endpoints.dart';

class AppointmentService extends BaseApiService {
  // Get all appointments for the logged-in user (patient or doctor)
  Future<dynamic> getUserAppointments() async {
    try {
      final response = await get(ApiEndpoints.appointments);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new appointment
  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required String dateTime,
    required String timeSlot,
    required String reasonForVisit,
    required double amount,
  }) async {
    try {
      final data = {
        'doctorId': doctorId,
        'dateTime': dateTime,
        'timeSlot': timeSlot,
        'reasonForVisit': reasonForVisit,
        'duration': 30 // Default duration in minutes as required by backend
      };

      print("Creating appointment with data: $data");
      final response = await post(ApiEndpoints.appointments, data: data);
      return response;
    } catch (e) {
      if (e is Exception && e.toString().contains('DioException')) {
        try {
          dynamic errorData = (e as dynamic).response?.data;
          if (errorData is Map<String, dynamic>) {
            return errorData;
          } else if (errorData is String) {
            return {'success': false, 'message': errorData};
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

// Get all appointments for the logged-in user
  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      final response = await get(ApiEndpoints.appointmentsByUser);
      if (response['success'] && response['appointments'] is List) {
        return List<Map<String, dynamic>>.from(response['appointments']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAppointmentStatus(
      String appointmentId, String status,
      {String? cancellationReason, String? notes}) async {
    try {
      Map<String, dynamic> data = {'status': status};

      // For cancellations, also set who cancelled it
      if (status == 'cancelled') {
        // Send cancellation reason if provided
        if (cancellationReason != null && cancellationReason.isNotEmpty) {
          data['cancellationReason'] = cancellationReason;
        }

        data['cancelledBy'] = 'doctor';
      }

      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      print("Updating appointment $appointmentId to status: $status");
      print("Using data: $data");

      final response =
          await put('/appointments/$appointmentId/status', data: data);

      if (response is Map<String, dynamic>) {
        return response;
      } else {
        return {
          'success': false,
          'message': 'Failed to update appointment status'
        };
      }
    } catch (e) {
      print("Error updating appointment status: $e");
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Add review to appointment
  Future<Map<String, dynamic>> addAppointmentReview(
      String appointmentId, int rating, String comment) async {
    try {
      final response = await post(
        '${ApiEndpoints.appointments}/$appointmentId/review',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Doctor-specific appointments
  Future<List<Map<String, dynamic>>> getDoctorAppointments() async {
    try {
      final response = await get(ApiEndpoints.appointmentsByDoctor);
      if (response['success'] && response['appointments'] is List) {
        return List<Map<String, dynamic>>.from(response['appointments']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get doctor availability slots
  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId) async {
    try {
      final response = await get('/doctors/$doctorId/availability');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update doctor availability
  Future<Map<String, dynamic>> updateDoctorAvailability(
      String doctorId, List<Map<String, dynamic>> availability) async {
    try {
      final response = await put(
        '/doctors/$doctorId/availability',
        data: {'availability': availability},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Cancel appointment with refund
  Future<Map<String, dynamic>> cancelAppointmentWithRefund({
    required String appointmentId,
    required String reason,
  }) async {
    try {
      print('Cancelling appointment with refund: $appointmentId');

      // First update the appointment status
      final appointmentResponse = await put(
        '/appointments/$appointmentId',
        data: {
          'status': 'cancelled',
          'cancelledBy': 'patient',
          'cancellationReason': reason
        },
      );

      if (appointmentResponse is Map &&
          appointmentResponse['success'] == true) {
        print('Appointment status updated to cancelled');

        // Now request the refund if there was a payment
        final payment = appointmentResponse['data']?['payment'];

        if (payment != null && payment['_id'] != null) {
          final paymentId = payment['_id'];

          // Process refund through the refund endpoint
          final refundResponse = await post(
            '/payments/$paymentId/refund',
            data: {
              'reason': reason,
            },
          );

          if (refundResponse is Map && refundResponse['success'] == true) {
            print('Refund processed successfully');
            return {
              'success': true,
              'message':
                  'Appointment cancelled and refund initiated successfully',
              'data': refundResponse['data']
            };
          } else {
            print('Failed to process refund: $refundResponse');
            return {
              'success': false,
              'message': refundResponse is Map
                  ? refundResponse['message']?.toString() ??
                      'Failed to process refund'
                  : 'Failed to process refund'
            };
          }
        }

        // If no payment found, just return success for the cancellation
        return {
          'success': true,
          'message': 'Appointment cancelled successfully'
        };
      } else {
        print('Failed to update appointment: $appointmentResponse');
        return {
          'success': false,
          'message': appointmentResponse is Map
              ? appointmentResponse['message']?.toString() ??
                  'Failed to cancel appointment'
              : 'Failed to cancel appointment'
        };
      }
    } catch (e) {
      print('Error cancelling appointment: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
