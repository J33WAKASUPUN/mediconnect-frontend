import 'package:flutter/material.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/notification/providers/notification_provider.dart';
import 'package:mediconnect/features/notification/widgets/notification_item.dart';
import 'package:provider/provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/utils/session_helper.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';

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
    final currentTime = "2025-06-01 19:18:55";
    final userLogin = "J33WAKASUPUN";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () async {
                    final provider = context.read<NotificationProvider>();

                    // Show a loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Marking all notifications as read...'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<NotificationProvider>().loadNotifications();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            color: AppColors.primary,
            width: double.infinity,
            // padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     const Text(
            //       'Your Notifications',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 18,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     const SizedBox(height: 4),
            //     Text(
            //       'Stay updated with all your health activities',
            //       style: TextStyle(
            //         color: Colors.white.withOpacity(0.8),
            //         fontSize: 14,
            //       ),
            //     ),
            //   ],
            // ),
          ),
          
          // Main content
          Expanded(
            child: Consumer<NotificationProvider>(
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
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
          
                return Column(
                  children: [
                    // Notification counts
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${notifications.length} Notifications',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${provider.unreadCount} unread',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Filter icon
                          IconButton(
                            icon: Icon(Icons.filter_list, color: Colors.grey.shade600),
                            onPressed: () {
                              // Show filter options dialog
                              _showFilterOptions(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Notification list
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: notifications.length + 1, // +1 for the session info
                        itemBuilder: (context, index) {
                          if (index == notifications.length) {
                            // Session info at the bottom
                            return Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted):',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 22),
                                    child: Text(
                                      currentTime,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Current User\'s Login:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 22),
                                    child: Text(
                                      userLogin,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                
                          final notification = notifications[index];
                          return NotificationItem(
                            notification: notification,
                            onTap: () => _handleNotificationTap(context, notification),
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
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Filter Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('All Notifications', Icons.all_inbox, true),
              _buildFilterOption('Unread Only', Icons.mark_email_unread_outlined, false),
              _buildFilterOption('Appointments', Icons.calendar_today, false),
              _buildFilterOption('Payments', Icons.payment, false),
              _buildFilterOption('Medical Records', Icons.medical_information, false),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : Colors.black,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: AppColors.primary,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        // Implement actual filtering logic here
      },
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
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