import 'package:flutter/material.dart';

class Review {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final int rating;
  final String review;
  final bool isAnonymous;
  final DoctorResponse? doctorResponse;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? patientDetails;
  final Map<String, dynamic>? appointmentDetails;

  Review({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.rating,
    required this.review,
    this.isAnonymous = false,
    this.doctorResponse,
    required this.createdAt,
    required this.updatedAt,
    this.patientDetails,
    this.appointmentDetails,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'],
      appointmentId: json['appointmentId'],
      patientId: json['patientId'] is Map 
        ? json['patientId']['_id'] 
        : json['patientId'],
      doctorId: json['doctorId'] is Map 
        ? json['doctorId']['_id'] 
        : json['doctorId'],
      rating: json['rating'],
      review: json['review'],
      isAnonymous: json['isAnonymous'] ?? false,
      doctorResponse: json['doctorResponse'] != null
          ? DoctorResponse.fromJson(json['doctorResponse'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      patientDetails: json['patientId'] is Map 
          ? json['patientId'] as Map<String, dynamic>
          : null,
      appointmentDetails: json['appointmentId'] is Map 
          ? json['appointmentId'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'rating': rating,
      'review': review,
      'isAnonymous': isAnonymous,
    };
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get patientName {
    if (patientDetails == null) return isAnonymous ? 'Anonymous User' : 'Patient';
    if (isAnonymous) return 'Anonymous User';
    return '${patientDetails!['firstName']} ${patientDetails!['lastName']}';
  }

  String? get patientProfilePicture {
    if (patientDetails == null || isAnonymous) return null;
    return patientDetails!['profilePicture'];
  }
}

class DoctorResponse {
  final String content;
  final DateTime respondedAt;

  DoctorResponse({
    required this.content,
    required this.respondedAt,
  });

  factory DoctorResponse.fromJson(Map<String, dynamic> json) {
    return DoctorResponse(
      content: json['content'],
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'respondedAt': respondedAt.toIso8601String(),
    };
  }

  String get formattedDate {
    return '${respondedAt.day}/${respondedAt.month}/${respondedAt.year}';
  }
}

// Class to hold analytics data returned from the backend
class ReviewAnalytics {
  final Map<String, dynamic> overall;
  final Map<String, int> ratingDistribution;
  final Map<String, Map<String, dynamic>> monthlyStats;
  final DateTime lastUpdated;

  ReviewAnalytics({
    required this.overall,
    required this.ratingDistribution,
    required this.monthlyStats,
    required this.lastUpdated,
  });

  factory ReviewAnalytics.fromJson(Map<String, dynamic> json) {
    // Convert rating distribution
    final Map<String, int> distribution = {};
    final ratingData = json['ratingDistribution'] as Map<String, dynamic>;
    ratingData.forEach((key, value) {
      distribution[key] = value as int;
    });
    
    // Convert monthly stats
    final Map<String, Map<String, dynamic>> monthly = {};
    final monthlyData = json['monthlyStats'] as Map<String, dynamic>;
    monthlyData.forEach((key, value) {
      monthly[key] = value as Map<String, dynamic>;
    });

    return ReviewAnalytics(
      overall: json['overall'] as Map<String, dynamic>,
      ratingDistribution: distribution,
      monthlyStats: monthly,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}