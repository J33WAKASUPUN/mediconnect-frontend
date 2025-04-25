import 'package:flutter/material.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _usingLocalState = false;
  String? _error;

  NotificationProvider({required ApiService apiService})
      : _apiService = apiService;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((notif) => !notif.isRead).toList();
  int get unreadCount {
    final count = _notifications.where((notif) => notif.isRead == false).length;
    print("Calculating unread count: $count");
    return count;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("Loading notifications from API...");
      final jsonList = await _apiService.getUserNotifications();
      print("Received ${jsonList.length} notifications from API");

      // Process notifications and handle errors
      _notifications = [];
      for (var json in jsonList) {
        try {
          final notification = AppNotification.fromJson(json);
          _notifications.add(notification);
        } catch (e) {
          print("Error parsing notification: $e");
          print("Problematic JSON: $json");
        }
      }

      // Sort by timestamp, newest first
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print("Successfully processed ${_notifications.length} notifications");
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error loading notifications: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      if (!_usingLocalState) {
        try {
          await _apiService.markNotificationAsRead(notificationId);
        } catch (e) {
          print("API call failed, using local state: $e");
          _usingLocalState = true;
        }
      }

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          relatedId: _notifications[index].relatedId,
          timestamp: _notifications[index].timestamp,
          isRead: true,
        );

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print("Error marking notification as read: $e");
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get all unread notification IDs
      final unreadIds = _notifications
          .where((notification) => !notification.isRead)
          .map((notification) => notification.id)
          .toList();

      if (unreadIds.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      print("Marking ${unreadIds.length} notifications as read");
      final result = await _apiService.markAllNotificationsAsRead(unreadIds);

      // If we successfully marked some notifications as read, reload
      if (result['success'] == true && result['count'] > 0) {
        await loadNotifications();
      }

      _isLoading = false;
      notifyListeners();
      return result['success'] == true;
    } catch (e) {
      print("Error marking all notifications as read: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
