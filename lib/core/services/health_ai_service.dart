import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mediconnect/config/api_endpoints.dart';
import 'package:mediconnect/core/models/health_ai_model.dart';
import 'package:mediconnect/core/services/base_api_service.dart';
import 'package:dio/dio.dart';
import 'package:mediconnect/features/messages/widgets/web_file_uploader.dart';

class HealthAIService extends BaseApiService {
  // Create a new health conversation session
  Future<HealthSession> createSession({String userType = 'patient'}) async {
    try {
      final response = await post(
        ApiEndpoints.healthInsightsSessions,
        data: {'userType': userType},
      );

      return HealthSession.fromJson(response['data']);
    } catch (e) {
      print('Error creating health session: $e');
      rethrow;
    }
  }

  // Get all health sessions for current user
  Future<List<HealthSession>> getSessions() async {
    try {
      final response = await get(ApiEndpoints.healthInsightsSessions);

      if (response['success'] != true) {
        throw Exception('Failed to fetch sessions: ${response['message']}');
      }

      final data = response['data'] as List;
      return data.map((json) => HealthSession.fromJson(json)).toList();
    } catch (e) {
      print('Error getting health sessions: $e');
      rethrow;
    }
  }

  // Get a specific session with messages
  Future<Map<String, dynamic>> getSession(String sessionId) async {
    try {
      final response =
          await get('${ApiEndpoints.healthInsightsSessions}/$sessionId');

      if (response['success'] != true) {
        throw Exception('Failed to fetch session: ${response['message']}');
      }

      final sessionData = response['data']['session'];
      final messagesData = response['data']['messages'] as List;

      return {
        'session': HealthSession.fromJson(sessionData),
        'messages':
            messagesData.map((json) => HealthMessage.fromJson(json)).toList(),
      };
    } catch (e) {
      print('Error getting health session: $e');
      rethrow;
    }
  }

  // Delete a session
  Future<bool> deleteSession(String sessionId) async {
    try {
      final response = await delete(
        '${ApiEndpoints.healthInsightsSessions}/$sessionId',
      );

      return response['success'] == true;
    } catch (e) {
      print('Error deleting health session: $e');
      rethrow;
    }
  }

  // Send message and get AI response
  Future<Map<String, dynamic>> sendMessage(
      String sessionId, String content) async {
    try {
      final response = await post(
        ApiEndpoints.healthInsightsMessages,
        data: {
          'sessionId': sessionId,
          'content': content,
        },
      );

      if (response['success'] != true) {
        throw Exception('Failed to send message: ${response['message']}');
      }

      final data = response['data'];
      return {
        'userMessage': HealthMessage.fromJson(data['userMessage']),
        'assistantMessage': HealthMessage.fromJson(data['assistantMessage']),
        'tokenUsage': data['usage'],
      };
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Analyze medical image
  Future<Map<String, dynamic>> analyzeImage(dynamic file,
      {String? prompt}) async {
    try {
      final token = getAuthToken();
      final url =
          '${ApiEndpoints.baseUrl}${ApiEndpoints.healthInsightsAnalyzeImage}';

      // Use WebSafeFileUploader for consistent handling across platforms
      Map<String, String> fields = {};
      if (prompt != null) {
        fields['prompt'] = prompt;
      }

      final result = await WebSafeFileUploader.uploadFile(
        url: url,
        token: token,
        file: file,
        fields: fields,
      );

      if (result['success'] == true) {
        return result['data'];
      } else {
        throw Exception(result['message'] ?? 'Failed to analyze image');
      }
    } catch (e) {
      print('Error analyzing image: $e');
      rethrow;
    }
  }

  // Get sample topics for new users
  Future<List<String>> getSampleTopics() async {
    try {
      final response = await get(ApiEndpoints.healthInsightsSampleTopics);

      if (response['success'] != true) {
        throw Exception('Failed to get sample topics: ${response['message']}');
      }

      return List<String>.from(response['data']);
    } catch (e) {
      print('Error getting sample topics: $e');
      return []; // Return empty list on error
    }
  }

  // Analyze document
  Future<String> analyzeDocument(String text,
      {String documentType = 'general'}) async {
    try {
      final response = await post(
        ApiEndpoints.healthInsightsAnalyzeDocument,
        data: {
          'text': text,
          'documentType': documentType,
        },
      );

      if (response['success'] != true) {
        throw Exception('Failed to analyze document: ${response['message']}');
      }

      return response['data']['analysis'];
    } catch (e) {
      print('Error analyzing document: $e');
      rethrow;
    }
  }
}
