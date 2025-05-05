import 'base_api_service.dart';
import '../../config/api_endpoints.dart';

class NotificationService extends BaseApiService {
  // Get all notifications for the logged-in user
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final response = await get(ApiEndpoints.notifications);

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> notificationsData = response['data'];
        return List<Map<String, dynamic>>.from(notificationsData);
      } else if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    try {
      final response =
          await put('${ApiEndpoints.notifications}/$notificationId');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to mark notification as read: $e'
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead(
      List<String> notificationIds) async {
    try {
      // Track success count
      int successCount = 0;

      // Make individual requests for each notification
      for (String id in notificationIds) {
        try {
          final result = await markNotificationAsRead(id);
          if (result['success'] == true) {
            successCount++;
          }
        } catch (e) {
          print("Error marking notification $id as read: $e");
        }
      }

      return {
        'success': true,
        'message':
            'Marked $successCount/${notificationIds.length} notifications as read',
        'count': successCount
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to mark notifications as read: $e'
      };
    }
  }

  // Create notification
  Future<Map<String, dynamic>> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      final data = {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'relatedId': relatedId,
      };

      final response = await post(ApiEndpoints.notifications, data: data);
      return response;
    } catch (e) {
      // Just log the error, don't throw since the notification is not critical
      print("Error creating notification (this is not critical): $e");
      return {'success': false, 'message': 'Notification API unavailable'};
    }
  }
}
