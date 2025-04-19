import 'package:flutter/material.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationProvider({required ApiService apiService})
      : _apiService = apiService;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => 
      _notifications.where((notif) => !notif.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final jsonList = await _apiService.getUserNotifications();
      _notifications = jsonList.map((json) => AppNotification.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      
      // Update local state
      _notifications = _notifications.map((notification) {
        if (notification.id == notificationId) {
          return AppNotification(
            id: notification.id,
            userId: notification.userId,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            relatedId: notification.relatedId,
            timestamp: notification.timestamp,
            isRead: true,
          );
        }
        return notification;
      }).toList();
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _apiService.markAllNotificationsAsRead();
      
      // Update local state
      _notifications = _notifications.map((notification) {
        return AppNotification(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          relatedId: notification.relatedId,
          timestamp: notification.timestamp,
          isRead: true,
        );
      }).toList();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}