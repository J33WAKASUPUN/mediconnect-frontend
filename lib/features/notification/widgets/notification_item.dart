import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/notification_model.dart';
import '../../../shared/constants/colors.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    // Use the isRead field directly from the notification
    final isUnread = !notification.isRead;

    return Column(
      children: [
        InkWell(
          onTap: () {
            // Mark as read when tapped
            if (isUnread) {
              onMarkRead();
            }
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            color: isUnread ? Colors.white : const Color(0xFFF6F6F6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeago.format(notification.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          if (isUnread)
                            InkWell(
                              onTap: onMarkRead,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Mark as read',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}