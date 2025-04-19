import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/notification_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? Colors.transparent 
              : notification.color.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
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
                          style: AppStyles.bodyText1.copyWith(
                            fontWeight: notification.isRead 
                                ? FontWeight.normal 
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(notification.timestamp),
                        style: AppStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: AppStyles.bodyText2,
                  ),
                ],
              ),
            ),
            
            // Read indicator
            if (!notification.isRead)
              InkWell(
                onTap: onMarkRead,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.circle,
                    color: AppColors.primary,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}