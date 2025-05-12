import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleMedicationReminderService {
  // Plugin instance
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Storage key
  final String _reminderStatusKey = 'simple_medication_reminders';
  
  // Constructor with initialization
  SimpleMedicationReminderService() {
    _initializeNotifications();
  }
  
  // Initialize notifications - called in constructor
  Future<void> _initializeNotifications() async {
    try {
      // Android settings
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialization settings
      const InitializationSettings initSettings = 
          InitializationSettings(android: androidSettings);
      
      // Initialize
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          print('Notification clicked: ${response.payload}');
        },
      );
      
      // Request permissions
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
          
      print('Notification service initialized');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
  
  // Simple method to get active reminders from storage
  Future<Set<String>> getActiveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> activeIds = prefs.getStringList(_reminderStatusKey) ?? [];
    return activeIds.toSet();
  }
  
  // Check if reminder is active
  Future<bool> isReminderActive(String medicationId) async {
    final activeReminders = await getActiveReminders();
    return activeReminders.contains(medicationId);
  }
  
  // Toggle reminder status
  Future<bool> toggleReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
  }) async {
    try {
      final Set<String> activeReminders = await getActiveReminders();
      final bool isCurrentlyActive = activeReminders.contains(medicationId);
      
      // Toggle status
      if (isCurrentlyActive) {
        activeReminders.remove(medicationId);
        await _cancelReminder(medicationId);
      } else {
        activeReminders.add(medicationId);
        await _showDailyReminder(medicationId, medicationName, dosage);
      }
      
      // Save updated status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_reminderStatusKey, activeReminders.toList());
      
      return !isCurrentlyActive;
    } catch (e) {
      print('Error toggling reminder: $e');
      return false;
    }
  }
  
  // Show a daily reminder
  Future<void> _showDailyReminder(
    String medicationId, 
    String medicationName, 
    String dosage
  ) async {
    try {
      final int notificationId = medicationId.hashCode.abs();
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Reminders to take your medications',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
      );
      
      final NotificationDetails details = NotificationDetails(android: androidDetails);
      
      // Use simple daily notification - no timezone dependency
      await _notificationsPlugin.periodicallyShow(
        notificationId,
        'Medication Reminder',
        'Time to take $medicationName - $dosage',
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: medicationId,
      );
      
      print('Scheduled daily reminder for $medicationName');
    } catch (e) {
      print('Error showing reminder: $e');
    }
  }
  
  // Cancel a reminder
  Future<void> _cancelReminder(String medicationId) async {
    try {
      final int notificationId = medicationId.hashCode.abs();
      await _notificationsPlugin.cancel(notificationId);
      print('Cancelled reminder for $medicationId');
    } catch (e) {
      print('Error cancelling reminder: $e');
    }
  }
}