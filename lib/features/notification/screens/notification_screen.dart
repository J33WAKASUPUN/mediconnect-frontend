// File: lib/features/notification/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/notification/providers/notification_provider.dart';
import 'package:mediconnect/features/notification/widgets/notification_item.dart';
import 'package:provider/provider.dart';
import '../../../../../../../core/models/notification_model.dart';
import '../../../../../../../core/utils/session_helper.dart';
import '../../../../../../../shared/constants/colors.dart';
import '../../../../../../../shared/constants/styles.dart';
import '../../../../../../../shared/widgets/error_view.dart';
import '../../../../../../../shared/widgets/loading_indicator.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<NotificationProvider>().loadNotifications();
        _debugNotificationState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = SessionHelper.getCurrentUTC();
    final userLogin = SessionHelper.getUserLogin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () async {
                    final provider = context.read<NotificationProvider>();

                    // Show a loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Marking all notifications as read...')),
                    );

                    // Mark all as read
                    final success = await provider.markAllAsRead();

                    // Show result
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'All notifications marked as read'
                              : 'Failed to mark all notifications as read'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NotificationProvider>().loadNotifications();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () {
                provider.loadNotifications();
              },
            );
          }

          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: AppStyles.heading2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: AppStyles.bodyText1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount:
                      notifications.length + 1, // +1 for the session info
                  itemBuilder: (context, index) {
                    if (index == notifications.length) {
                      // Session info at the bottom
                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Date and Time (UTC): $currentTime',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current User\'s Login: $userLogin',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    final notification = notifications[index];
                    return NotificationItem(
                      notification: notification,
                      onTap: () =>
                          _handleNotificationTap(context, notification),
                      onMarkRead: () {
                        if (!notification.isRead) {
                          provider.markAsRead(notification.id);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // PUT THE METHOD HERE - inside the _NotificationScreenState class
  void _handleNotificationTap(
      BuildContext context, AppNotification notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case 'appointment':
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            context.read<AuthProvider>().user?.role == 'patient'
                ? '/patient/appointments'
                : '/doctor/appointments',
          );
        }
        break;
      case 'payment':
        if (notification.relatedId != null) {
          // Navigate to appointments as you may not have a separate payments screen
          Navigator.pushNamed(context, '/patient/appointments');
        }
        break;
      case 'medical_record':
        if (notification.relatedId != null) {
          // Instead of a dedicated medical records screen, go to appointments
          // as medical records are tied to appointments in your UI flow
          Navigator.pushNamed(
            context,
            context.read<AuthProvider>().user?.role == 'patient'
                ? '/patient/appointments'
                : '/doctor/appointments',
          );
        }
        break;
      default:
        // No navigation for system messages
        break;
    }
  }

  void _debugNotificationState() {
    final provider = context.read<NotificationProvider>();
    print("======= NOTIFICATION DEBUG =======");
    print("Total notifications: ${provider.notifications.length}");
    print("Unread count: ${provider.unreadNotifications.length}");

    for (var i = 0; i < provider.notifications.length; i++) {
      final n = provider.notifications[i];
      print("[$i] ${n.id} - ${n.title} - Read: ${n.isRead}");
    }
    print("=================================");
  }
}
