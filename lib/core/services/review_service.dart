import 'package:mediconnect/config/api_endpoints.dart';
import 'package:mediconnect/core/services/base_api_service.dart';

class ReviewService extends BaseApiService {
  ReviewService() : super();

  // Create a review for an appointment
  Future<Map<String, dynamic>> createReview({
  required String appointmentId,
  required int rating,
  required String review,
  bool isAnonymous = false,
}) async {
  try {
    // Ensure we have a valid auth token
    final token = getAuthToken();
    if (token.isEmpty) {
      print('Warning: No auth token available for review creation');
      return {'success': false, 'message': 'Authentication token is missing'};
    }
    
    // Debug print
    print('Creating review with token: ${token.substring(0, 10)}...');
    print('Full endpoint: ${ApiEndpoints.baseUrl}/reviews/$appointmentId');

    final response = await post('/reviews/$appointmentId', data: {
      'rating': rating,
      'review': review,
      'isAnonymous': isAnonymous,
    });

    return response;
  } catch (e) {
    print('Error creating review: $e');
    return {'success': false, 'message': e.toString()};
  }
}

  // Get all reviews for a doctor
  Future<Map<String, dynamic>> getDoctorReviews(String doctorId,
      {int page = 1, int limit = 10}) async {
    try {
      final response =
          await get('/reviews/doctor/$doctorId?page=$page&limit=$limit');
      return response;
    } catch (e) {
      print('Error getting doctor reviews: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add doctor's response to a review
  Future<Map<String, dynamic>> addDoctorResponse({
    required String reviewId,
    required String response,
  }) async {
    try {
      final apiResponse = await put('/reviews/$reviewId/response', data: {
        'response': response,
      });

      return apiResponse;
    } catch (e) {
      print('Error adding doctor response: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get analytics for a doctor's reviews
  Future<Map<String, dynamic>> getDoctorReviewAnalytics(String doctorId) async {
    try {
      final response = await get('/reviews/doctor/$doctorId/analytics');
      return response;
    } catch (e) {
      print('Error getting doctor review analytics: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
