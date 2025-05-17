// lib/widgets/messages/conversation_tile.dart
import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/conversation.dart';
import 'package:mediconnect/core/utils/date_formatter.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final Map<String, dynamic> otherUser;
  final VoidCallback onTap;

  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.otherUser,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = conversation.unreadCount > 0;
    final lastMessage = conversation.lastMessage;
    
    // Get appropriate message preview text
    String messagePreview = 'Start a conversation';
    String timeText = '';
    
    if (lastMessage != null) {
      if (lastMessage['messageType'] == 'text') {
        messagePreview = lastMessage['content'] ?? '';
      } else if (lastMessage['messageType'] == 'image') {
        messagePreview = '📷 Image';
      } else if (lastMessage['messageType'] == 'document') {
        messagePreview = '📄 Document';
      }
      
      // Add "Forwarded" prefix if needed
      if (lastMessage['forwardedFrom'] != null) {
        messagePreview = 'Forwarded: $messagePreview';
      }
      
      // Format time
      if (lastMessage['createdAt'] != null) {
        final DateTime time = DateTime.parse(lastMessage['createdAt']);
        timeText = DateFormatter.formatConversationTime(time);
      }
    }
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: hasUnread ? 3 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: otherUser['profilePicture'] != null
                    ? NetworkImage(otherUser['profilePicture'])
                    : null,
                child: otherUser['profilePicture'] == null
                    ? Text(
                        '${otherUser['firstName']?[0] ?? ''}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${otherUser['firstName'] ?? ''} ${otherUser['lastName'] ?? ''}',
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeText.isNotEmpty)
                          Text(
                            timeText,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messagePreview,
                            style: TextStyle(
                              color: hasUnread ? Colors.black87 : Colors.grey,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
    );
  }
}