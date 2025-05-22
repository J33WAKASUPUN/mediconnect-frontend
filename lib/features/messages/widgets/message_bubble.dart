import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/utils/date_formatter.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/widgets/document_handler.dart';
import 'package:mediconnect/features/messages/widgets/message_file_viewer.dart';
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
    // Common container styling based on user
    final bubbleDecoration = BoxDecoration(
      color: isCurrentUser
          ? Theme.of(context).primaryColor.withOpacity(0.8)
          : Theme.of(context).primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );

    // Handle different message types
    if (message.messageType == 'text') {
      // Text message
      return Container(
        padding: EdgeInsets.all(12),
        decoration: bubbleDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add reply preview if message is a reply
            if (_isReplyMessage()) _buildReplyPreview(context),

            // Main message text
            Text(
              message.content ?? '',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),

            // Edit indicator
            if (message.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Edited',
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.5),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (message.messageType == 'image') {
      // Image message
      return Container(
        padding: EdgeInsets.all(4),
        decoration: bubbleDecoration,
        child: MessageFileViewer(message: message, isPreview: true),
      );
    } else if (message.messageType == 'document') {
      // Document message
      return Container(
        padding: EdgeInsets.all(4),
        decoration: bubbleDecoration,
        child: MessageFileViewer(message: message, isPreview: true),
      );
    } else {
      // Default/unknown type
      return Container(
        padding: EdgeInsets.all(12),
        decoration: bubbleDecoration,
        child: Text(
          'Unsupported message type: ${message.messageType}',
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
  }

  // Check if this is a reply message
  bool _isReplyMessage() {
    return message.metadata.containsKey('replyTo') &&
        message.metadata['replyTo'] != null &&
        message.metadata['replyTo']['messageId'] != null;
  }

  // Build a preview of the message being replied to
  Widget _buildReplyPreview(BuildContext context) {
    final replyData = message.metadata['replyTo'];
    final replyContent = replyData['content'] ?? '';
    final replyType = replyData['messageType'] ?? 'text';

    // Don't show anything if no valid reply data
    if (replyContent.isEmpty &&
        replyType != 'image' &&
        replyType != 'document') {
      return SizedBox();
    }

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.white.withOpacity(0.2)
            : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.3)
              : Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show reply type indicator
          if (replyType == 'text' && replyContent.isNotEmpty)
            Text(
              replyContent,
              style: TextStyle(
                color: isCurrentUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else if (replyType == 'image')
            Row(
              children: [
                Icon(
                  Icons.image,
                  size: 14,
                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                ),
                SizedBox(width: 4),
                Text(
                  'Image',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else if (replyType == 'document')
            Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 14,
                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                ),
                SizedBox(width: 4),
                Text(
                  'Document',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimeAndStatus() {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());
    final isRead = message.metadata['status'] == 'read';
    
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 4),
            Icon(
              isRead ? Icons.done_all : Icons.done,
              size: 12,
              color: isRead ? Colors.blue : Colors.grey[600],
            ),
          ],
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
    // Make sure we have file data
    if (message.file == null || message.file!['url'] == null) {
      print('No valid image URL in message: ${message.id}');
      return Container(
        height: 150,
        width: 150,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    }

    String imageUrl = message.file!['url'];
    print('Displaying image from URL: $imageUrl'); // Debug log

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
                  appBar: AppBar(
                    title: const Text('Image'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // Implement image download if needed
                        },
                      ),
                    ],
                  ),
                  body: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) => Container(
                          height: MediaQuery.of(context).size.height * 0.3,
                          width: MediaQuery.of(context).size.width * 0.8,
                          color: Colors.grey[300],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) {
                          print('Error loading image: $error');
                          return Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: MediaQuery.of(context).size.width * 0.8,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
                maxHeight: 250,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => Container(
                  height: 150,
                  width: 150,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) {
                  print('Error loading image thumbnail: $error');
                  return Container(
                    height: 150,
                    width: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentMessage(BuildContext context) {
    if (message.file == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("Document unavailable",
                style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87)),
          ],
        ),
      );
    }

    final fileName = message.file!['filename'] ?? 'Document';
    final fileSize = message.file!['size'] ?? 0;
    final fileUrl = message.file!['url'];
    final fileType = _getFileTypeIcon(fileName);
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
          fileType,
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
          IconButton(
            icon: Icon(
              Icons.download,
              color:
                  isCurrentUser ? Colors.white : Theme.of(context).primaryColor,
              size: 20,
            ),
            onPressed: fileUrl == null
                ? null
                : () => DocumentHandler.downloadAndOpenDocument(
                    context, fileUrl, fileName),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            visualDensity: VisualDensity.compact,
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
          size: 24,
        );
      case 'doc':
      case 'docx':
        return Icon(
          Icons.description,
          color: isCurrentUser ? Colors.white : Colors.blue,
          size: 24,
        );
      case 'xls':
      case 'xlsx':
        return Icon(
          Icons.insert_chart,
          color: isCurrentUser ? Colors.white : Colors.green,
          size: 24,
        );
      case 'txt':
        return Icon(
          Icons.subject,
          color: isCurrentUser ? Colors.white : Colors.grey,
          size: 24,
        );
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icon(
          Icons.image,
          color: isCurrentUser ? Colors.white : Colors.purple,
          size: 24,
        );
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icon(
          Icons.video_file,
          color: isCurrentUser ? Colors.white : Colors.orange,
          size: 24,
        );
      default:
        return Icon(
          Icons.insert_drive_file,
          color: isCurrentUser ? Colors.white : Colors.grey,
          size: 24,
        );
    }
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
