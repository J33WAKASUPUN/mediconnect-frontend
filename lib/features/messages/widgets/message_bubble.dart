import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/utils/date_formatter.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/widgets/reaction_display.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final Map<String, dynamic> otherUser;
  final Function() onLongPress;
  final Function(String) onReactionTap;
  final bool isSelected;
  final Function()? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.otherUser,
    required this.onLongPress,
    required this.onReactionTap,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isCurrentUser ? 80 : 0,
            right: isCurrentUser ? 0 : 80,
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (message.forwardedFrom != null) _buildForwardedHeader(),

              // Add reply info if this is a reply
              if (message.metadata.containsKey('replyTo'))
                _buildReplyInfo(context),

              _buildMessageContent(context),
              if (message.hasReactions)
                ReactionDisplay(
                  reactions: message.reactions,
                  onTap: onReactionTap,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyInfo(BuildContext context) {
    print('Message metadata for reply check: ${message.metadata}');

    // Check if replyTo exists in metadata
    if (!message.metadata.containsKey('replyTo')) {
      print('No replyTo found in message metadata');
      return SizedBox.shrink();
    }

    final replyToData = message.metadata['replyTo'];
    if (replyToData == null) {
      print('replyTo data is null');
      return SizedBox.shrink();
    }

    print('Found replyTo data: $replyToData');

    // Extract reply information
    final replySenderId = replyToData['senderId']?.toString();
    final replyContent = replyToData['content']?.toString() ?? '';
    final replyMessageType = replyToData['messageType']?.toString() ?? 'text';

    // Skip if missing critical data
    if (replySenderId == null) {
      print('Missing required sender ID in reply data');
      return SizedBox.shrink();
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isReplyFromCurrentUser = replySenderId == authProvider.user?.id;
    final replySenderName =
        isReplyFromCurrentUser ? 'You' : otherUser['firstName'];

    // WhatsApp-style reply display
    return Container(
      margin: EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).primaryColor.withOpacity(0.7)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: isCurrentUser ? Radius.circular(8) : Radius.circular(0),
          bottomRight: isCurrentUser ? Radius.circular(0) : Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(
            color: isReplyFromCurrentUser ? Colors.blue : Colors.green,
            width: 4,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replySenderName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isReplyFromCurrentUser
                  ? (isCurrentUser ? Colors.white : Colors.blue)
                  : (isCurrentUser ? Colors.white : Colors.green),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 2),
          if (replyMessageType == 'text')
            Text(
              replyContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isCurrentUser
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey.shade700,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  replyMessageType == 'image'
                      ? Icons.image
                      : Icons.insert_drive_file,
                  size: 12,
                  color: isCurrentUser
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey.shade700,
                ),
                SizedBox(width: 4),
                Text(
                  replyMessageType == 'image' ? 'Photo' : 'Document',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildForwardedHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forward,
            size: 14,
            color: Colors.grey,
          ),
          SizedBox(width: 4),
          Text(
            'Forwarded',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Adjust the border radius based on whether there's a reply
    // to create a connected bubble effect like WhatsApp
    final bool hasReply = message.metadata.containsKey('replyTo');

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).primaryColor
            : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16).copyWith(
          topLeft: hasReply && !isCurrentUser
              ? Radius.circular(0)
              : Radius.circular(16),
          topRight: hasReply && isCurrentUser
              ? Radius.circular(0)
              : Radius.circular(16),
          bottomRight: isCurrentUser ? Radius.circular(0) : Radius.circular(16),
          bottomLeft: isCurrentUser ? Radius.circular(16) : Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.messageType == 'text')
            _buildTextMessage(context)
          else if (message.messageType == 'image')
            _buildImageMessage(context)
          else if (message.messageType == 'document')
            _buildDocumentMessage(context),
          SizedBox(height: 4),
          _buildMessageFooter(context),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context) {
    return Text(
      message.content ?? '',
      style: TextStyle(
        color: isCurrentUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Show full image
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(),
                  body: Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: message.file!['url'],
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.file!['url'],
              placeholder: (context, url) => SizedBox(
                height: 200,
                width: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                width: 200,
                color: Colors.grey[300],
                child: Icon(Icons.error),
              ),
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentMessage(BuildContext context) {
    final fileName = message.file!['filename'] ?? 'Document';
    final fileSize = message.file!['fileSize'] ?? 0;
    final formattedSize = _formatFileSize(fileSize);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isCurrentUser ? Colors.white : Colors.grey,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedSize,
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.download,
            color:
                isCurrentUser ? Colors.white : Theme.of(context).primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text(
              'Edited',
              style: TextStyle(
                color:
                    isCurrentUser ? Colors.white.withOpacity(0.7) : Colors.grey,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Text(
          DateFormatter.formatMessageTime(message.createdAt),
          style: TextStyle(
            color: isCurrentUser ? Colors.white.withOpacity(0.7) : Colors.grey,
            fontSize: 10,
          ),
        ),
        if (isCurrentUser) ...[
          SizedBox(width: 4),
          Icon(
            message.metadata['status'] == 'read' ? Icons.done_all : Icons.done,
            size: 14,
            color: message.metadata['status'] == 'read'
                ? Colors.blue
                : Colors.white.withOpacity(0.7),
          ),
        ],
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
