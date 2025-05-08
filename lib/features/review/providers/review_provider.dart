import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/review_model.dart';
import '../../../core/services/api_service.dart';

class ReviewProvider with ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _error;
  List<Review> _doctorReviews = [];
  Map<String, dynamic>? _pagination;
  double _averageRating = 0.0;
  ReviewAnalytics? _analytics;

  ReviewProvider({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Review> get doctorReviews => _doctorReviews;
  double get averageRating => _averageRating;
  ReviewAnalytics? get analytics => _analytics;

  // Get pagination info
  int get currentPage => _pagination != null ? _pagination!['current'] : 1;
  int get totalPages => _pagination != null ? _pagination!['total'] : 1;
  int get totalReviews =>
      _pagination != null ? _pagination!['totalReviews'] : 0;
  bool get hasMorePages => currentPage < totalPages;

  void _debugPrintReviewJson(Map<String, dynamic> json) {
    print('==== DEBUG REVIEW JSON ====');
    try {
      if (json.containsKey('data') && json['data'] is Map) {
        var data = json['data'];

        if (data.containsKey('reviews') &&
            data['reviews'] is List &&
            data['reviews'].isNotEmpty) {
          var firstReview = data['reviews'][0];
          print('First Review: $firstReview');

          print(
              'appointmentId type: ${firstReview['appointmentId'].runtimeType}');
          if (firstReview['appointmentId'] is Map) {
            print(
                '  appointmentId._id: ${firstReview['appointmentId']['_id']}');
            print(
                '  appointmentId.dateTime: ${firstReview['appointmentId']['dateTime']}');
          } else {
            print('  appointmentId value: ${firstReview['appointmentId']}');
          }

          print('patientId type: ${firstReview['patientId'].runtimeType}');
          if (firstReview['patientId'] is Map) {
            print('  patientId._id: ${firstReview['patientId']['_id']}');
            print(
                '  patientId.firstName: ${firstReview['patientId']['firstName']}');
          } else {
            print('  patientId value: ${firstReview['patientId']}');
          }
        } else {
          print('No reviews found in response');
        }
      } else {
        print('Invalid response format');
      }
    } catch (e) {
      print('Error parsing review JSON: $e');
    }
    print('==========================');
  }

  // Load reviews for a doctor
  Future<void> loadDoctorReviews(String doctorId,
      {int page = 1, int limit = 10, bool refresh = false}) async {
    if (refresh) {
      _doctorReviews = [];
      _pagination = null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getDoctorReviews(doctorId,
          page: page, limit: limit);
      _debugPrintReviewJson(response); // Debug print for review JSON

      if (response['success'] && response['data'] != null) {
        final data = response['data'];

        // Parse reviews
        final reviews = data['reviews'] as List<dynamic>;
        final List<Review> fetchedReviews =
            reviews.map((json) => Review.fromJson(json)).toList();

        if (refresh || page == 1) {
          _doctorReviews = fetchedReviews;
        } else {
          _doctorReviews.addAll(fetchedReviews);
        }

        // Parse pagination
        _pagination = data['pagination'];

        // Parse average rating
        _averageRating = (data['averageRating'] as num).toDouble();
      } else {
        _error = response['message'] ?? 'Failed to load reviews';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new review
  Future<bool> createReview({
    required String appointmentId,
    required int rating,
    required String review,
    bool isAnonymous = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createReview(
        appointmentId: appointmentId,
        rating: rating,
        review: review,
        isAnonymous: isAnonymous,
      );

      if (response['success']) {
        // Refresh the reviews list to include the new review
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to submit review';
        _isLoading = false;
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

  // Add doctor's response to a review
  Future<bool> addDoctorResponse({
    required String reviewId,
    required String response,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiResponse = await _apiService.addDoctorResponse(
        reviewId: reviewId,
        response: response,
      );

      if (apiResponse['success']) {
        // Update the local review with the new response
        final updatedReview = Review.fromJson(apiResponse['data']);
        final index = _doctorReviews.indexWhere((r) => r.id == reviewId);

        if (index >= 0) {
          _doctorReviews[index] = updatedReview;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = apiResponse['message'] ?? 'Failed to add response';
        _isLoading = false;
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

  // Load doctor review analytics
  Future<void> loadDoctorReviewAnalytics(String doctorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getDoctorReviewAnalytics(doctorId);

      if (response['success'] && response['data'] != null) {
        _analytics = ReviewAnalytics.fromJson(response['data']);
      } else {
        _error = response['message'] ?? 'Failed to load review analytics';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more reviews (pagination)
  Future<void> loadMoreReviews(String doctorId) async {
    if (!hasMorePages || _isLoading) return;
    await loadDoctorReviews(doctorId, page: currentPage + 1, refresh: false);
  }
}
