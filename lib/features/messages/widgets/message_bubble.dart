import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/utils/date_formatter.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/widgets/document_handler.dart';
import 'package:mediconnect/features/messages/widgets/message_file_viewer.dart';
import 'package:mediconnect/features/messages/widgets/reaction_display.dart';
import 'package:mediconnect/shared/constants/colors.dart';
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), // <- MODIFY THIS LINE
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left spacer for sent messages
          if (isCurrentUser) 
            SizedBox(width: MediaQuery.of(context).size.width * 0.10),
          
          // Message content
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.forwardedFrom != null) _buildForwardedHeader(),
                  
                  // Main message bubble
                  IntrinsicWidth(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                        minWidth: 0,
                      ),
                      child: _buildMessageContent(context),
                    ),
                  ),
                  
                  if (message.hasReactions)
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2, 
                        right: isCurrentUser ? 8 : 0,
                        left: isCurrentUser ? 0 : 8,
                      ),
                      child: ReactionDisplay(
                        reactions: message.reactions,
                        onTap: onReactionTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Right spacer for received messages
          if (!isCurrentUser) 
            SizedBox(width: MediaQuery.of(context).size.width * 0.10),
        ],
      ),
    );
  }

  Widget _buildForwardedHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forward,
            size: 12,
            color: Colors.grey,
          ),
          SizedBox(width: 2),
          Text(
            'Forwarded',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12, // <- MODIFY THIS to 12
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Get colors for the bubbles with slight transparency
    final senderBubbleColor = const Color.fromARGB(255, 66, 68, 214).withOpacity(1); 
    final receiverBubbleColor = const Color.fromARGB(255, 255, 255, 255).withOpacity(1); 
    
    // Configure the bubble shape with one sharp corner
    BorderRadius borderRadius = isCurrentUser 
        ? BorderRadius.only(
            topLeft: Radius.circular(12), 
            topRight: Radius.circular(12), 
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(1), // Sharper corner
          )
        : BorderRadius.only(
            topLeft: Radius.circular(1), // Sharper corner
            topRight: Radius.circular(12), 
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(12), 
          );
    
    // Configure the container for the message bubble
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isCurrentUser ? senderBubbleColor : receiverBubbleColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // If this is a reply message, add the reply info at the top
          if (message.metadata.containsKey('replyTo') && message.metadata['replyTo'] != null)
            _buildReplyInfo(context),
            
          // Main message content
          _buildMainMessageContent(context),
          
          // Time and status indicators
          Align(
            alignment: isCurrentUser ? Alignment.bottomRight : Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                right: isCurrentUser ? 6 : 0,
                left: isCurrentUser ? 0 : 6,
                bottom: 2,
                top: 1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormatter.formatMessageTime(message.createdAt),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white70 : Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    SizedBox(width: 2),
                    Icon(
                      message.metadata['status'] == 'read' ? Icons.done_all : Icons.done,
                      size: 10,
                      color: message.metadata['status'] == 'read' ? const Color.fromARGB(255, 45, 217, 252) : const Color.fromARGB(179, 255, 255, 255),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInfo(BuildContext context) {
    final replyData = message.metadata['replyTo'];
    if (replyData == null) return SizedBox.shrink();

    final replySenderId = replyData['senderId']?.toString();
    final replyContent = replyData['content']?.toString() ?? '';
    final replyMessageType = replyData['messageType']?.toString() ?? 'text';

    // Skip if missing critical data
    if (replySenderId == null) return SizedBox.shrink();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isReplyFromCurrentUser = replySenderId == authProvider.user?.id;
    final replySenderName = isReplyFromCurrentUser ? 'You' : otherUser['firstName'];

    // WhatsApp-style reply display with border and background
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 0, top: 4, left: 4, right: 4),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.shade200.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(
            color: isReplyFromCurrentUser ? Colors.blue : Colors.green,
            width: 3,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 4, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replySenderName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isReplyFromCurrentUser
                  ? Colors.blue
                  : Colors.green,
              fontSize: 12, // <- MODIFY THIS to 12
            ),
          ),
          SizedBox(height: 1),
          if (replyMessageType == 'text')
            Text(
              replyContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12, // <- MODIFY THIS to 12
                color: isCurrentUser
                    ? Colors.white
                    : Colors.grey[700],
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
                  size: 10,
                  color: isCurrentUser
                      ? Colors.white
                      : Colors.grey[700],
                ),
                SizedBox(width: 2),
                Text(
                  replyMessageType == 'image' ? 'Photo' : 'Document',
                  style: TextStyle(
                    fontSize: 12, // <- MODIFY THIS to 12
                    color: isCurrentUser
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildMainMessageContent(BuildContext context) {
    // Handle different message types
    if (message.messageType == 'text') {
      // Text message
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content ?? '',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 15, // <- MODIFY THIS to 15
              ),
            ),

            // Edit indicator
            if (message.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  'Edited',
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.5),
                    fontSize: 11, // <- MODIFY THIS to 11
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (message.messageType == 'image') {
      // Image message
      return _buildImageMessage(context);
    } else if (message.messageType == 'document') {
      // Document message
      return _buildDocumentMessage(context);
    } else {
      // Default/unknown type
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Unsupported message type: ${message.messageType}',
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black,
            fontStyle: FontStyle.italic,
            fontSize: 14, // <- MODIFY THIS to 14
          ),
        ),
      );
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    // Make sure we have file data
    if (message.file == null || message.file!['url'] == null) {
      return Container(
        height: 120,
        width: 120,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }

    String imageUrl = message.file!['url'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        onTap: () {
          // Show full-screen image when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: IconThemeData(color: Colors.white),
                  elevation: 0,
                ),
                body: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(2),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 250,
              maxHeight: 250,
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 250,
                  height: 200,
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[100],
                  child: Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentMessage(BuildContext context) {
    if (message.file == null) {
      return Container(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 14),
            SizedBox(width: 4),
            Text("Document unavailable",
                style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                    fontSize: 12)
            ),
          ],
        ),
      );
    }

    final fileName = message.file!['filename'] ?? 'Document';
    final fileSize = message.file!['size'] ?? 0;
    final fileUrl = message.file!['url'];
    final fileType = _getFileTypeIcon(fileName);
    final formattedSize = _formatFileSize(fileSize);

    // Truncate long file names
    final displayName = fileName.length > 20 
        ? fileName.substring(0, 15) + '...' + fileName.split('.').last
        : fileName;

    return Container(
      margin: EdgeInsets.all(4),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          fileType,
          SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13, // <- MODIFY THIS to 13
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
                    fontSize: 11, // <- MODIFY THIS to 11
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6),
          IconButton(
            icon: Icon(
              Icons.download,
              color: isCurrentUser ? Colors.white : AppColors.primary,
              size: 16,
            ),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: fileUrl == null
                ? null
                : () => DocumentHandler.downloadAndOpenDocument(
                      context, fileUrl, fileName),
          ),
        ],
      ),
    );
  }

  Icon _getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icon(
          Icons.picture_as_pdf,
          color: isCurrentUser ? Colors.white : Colors.red,
          size: 16,
        );
      case 'doc':
      case 'docx':
        return Icon(
          Icons.description,
          color: isCurrentUser ? Colors.white : Colors.blue,
          size: 16,
        );
      case 'xls':
      case 'xlsx':
        return Icon(
          Icons.insert_chart,
          color: isCurrentUser ? Colors.white : Colors.green,
          size: 16,
        );
      case 'txt':
        return Icon(
          Icons.subject,
          color: isCurrentUser ? Colors.white : Colors.grey,
          size: 16,
        );
      default:
        return Icon(
          Icons.insert_drive_file,
          color: isCurrentUser ? Colors.white : Colors.grey,
          size: 16,
        );
    }
  }

  String _formatFileSize(dynamic bytes) {
    // Handle null or non-numeric values
    if (bytes == null) return '0 B';

    // Convert string to int if needed
    int size;
    if (bytes is int) {
      size = bytes;
    } else if (bytes is String) {
      size = int.tryParse(bytes) ?? 0;
    } else {
      size = 0;
    }

    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
