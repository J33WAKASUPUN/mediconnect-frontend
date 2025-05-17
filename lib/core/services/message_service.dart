import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:mediconnect/config/api_endpoints.dart';
import 'base_api_service.dart';
import 'package:path/path.dart' as path;

class MessageService extends BaseApiService {
  // Get user conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await get('/messages/conversations');
      
      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      
      return [];
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  // Get messages for a conversation
  Future<Map<String, dynamic>> getMessages(String conversationId, {int page = 1, int limit = 20}) async {
    try {
      final response = await get(
        '/messages/$conversationId?page=$page&limit=$limit'
      );
      
      if (response['success'] == true) {
        return {
          'messages': response['data']['messages'] ?? [],
          'pagination': response['data']['pagination'] ?? {},
        };
      }
      
      return {'messages': [], 'pagination': {}};
    } catch (e) {
      print('Error getting messages: $e');
      return {'messages': [], 'pagination': {}};
    }
  }

  // Send a text message
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    String category = 'general', 
    String priority = 'normal',
    String relatedTo = 'none',
    String? referenceId,
  }) async {
    try {
      final data = {
        'receiverId': receiverId,
        'content': content,
        'category': category,
        'priority': priority,
        'relatedTo': relatedTo,
      };
      
      if (referenceId != null) {
        data['referenceId'] = referenceId;
      }
      
      final response = await post(
        '/messages',
        data: data,
      );
      
      return response;
    } catch (e) {
      print('Error sending message: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Send a file message (image or document)
  Future<Map<String, dynamic>> sendFileMessage({
    required String receiverId,
    required File file,
    String category = 'general',
    String priority = 'normal',
    String relatedTo = 'none',
    String? referenceId,
  }) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/messages/file');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header
      request.headers['Authorization'] = 'Bearer $currentToken';
      
      // Determine file type and content type
      String fileName = file.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();
      String contentType;
      
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        contentType = 'image/$extension';
      } else if (extension == 'pdf') {
        contentType = 'application/pdf';
      } else if (['doc', 'docx'].contains(extension)) {
        contentType = 'application/msword';
      } else if (['xls', 'xlsx'].contains(extension)) {
        contentType = 'application/vnd.ms-excel';
      } else {
        contentType = 'application/octet-stream';
      }
      
      // Add file
      request.files.add(
        http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );
      
      // Add text fields
      request.fields['receiverId'] = receiverId;
      request.fields['category'] = category;
      request.fields['priority'] = priority;
      request.fields['relatedTo'] = relatedTo;
      
      if (referenceId != null) {
        request.fields['referenceId'] = referenceId;
      }
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)['data']};
      } else {
        return {'success': false, 'message': 'Failed to send file: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error sending file message: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Edit a message
  Future<Map<String, dynamic>> editMessage(String messageId, String content) async {
    try {
      final response = await put(
        '/messages/$messageId',
        data: {'content': content},
      );
      
      return response;
    } catch (e) {
      print('Error editing message: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add reaction to a message
  Future<Map<String, dynamic>> addReaction(String messageId, String reaction) async {
    try {
      final response = await post(
        '/messages/$messageId/reactions',
        data: {'reaction': reaction},
      );
      
      return response;
    } catch (e) {
      print('Error adding reaction: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Remove reaction from a message
  Future<Map<String, dynamic>> removeReaction(String messageId, String reaction) async {
    try {
      final response = await delete(
        '/messages/$messageId/reactions/$reaction',
      );
      
      return response;
    } catch (e) {
      print('Error removing reaction: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Forward a message
  Future<Map<String, dynamic>> forwardMessage(String messageId, String receiverId) async {
    try {
      final response = await post(
        '/messages/$messageId/forward',
        data: {'receiverId': receiverId},
      );
      
      return response;
    } catch (e) {
      print('Error forwarding message: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Search messages
  Future<Map<String, dynamic>> searchMessages(String query, {
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/messages/search?query=$query&page=$page&limit=$limit';
      
      if (conversationId != null) {
        url += '&conversationId=$conversationId';
      }
      
      final response = await get(url);
      
      if (response['success'] == true) {
        return {
          'messages': response['data']['messages'] ?? [],
          'pagination': response['data']['pagination'] ?? {},
        };
      }
      
      return {'messages': [], 'pagination': {}};
    } catch (e) {
      print('Error searching messages: $e');
      return {'messages': [], 'pagination': {}};
    }
  }

  // Mark message as read
  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    try {
      final response = await put(
        '/messages/$messageId/read',
        data: {},
      );
      
      return response;
    } catch (e) {
      print('Error marking message as read: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await get('/messages/unread/count');
      
      if (response['success'] == true && response['data'] != null) {
        return response['data']['unreadCount'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await delete('/messages/$messageId');
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }
}