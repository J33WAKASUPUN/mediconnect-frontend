// lib/screens/messages/chat_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/utils/date_formatter.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/provider/message_provider.dart';
import 'package:mediconnect/features/messages/widgets/message_bubble.dart';
import 'package:mediconnect/features/messages/widgets/message_input.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  ChatDetailScreen({
    required this.conversationId,
    required this.otherUser,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _setupProviders();
    _scrollController.addListener(_scrollListener);
  }

  void _setupProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Set current conversation
      messageProvider.setCurrentConversation(
        widget.conversationId,
        widget.otherUser['_id'],
      );

      // Load messages
      messageProvider.loadMessages(refresh: true);
    });
  }

  void _scrollListener() {
    // Show scroll to bottom button when not at bottom
    if (_scrollController.offset > 500 && !_showScrollToBottom) {
      setState(() {
        _showScrollToBottom = true;
      });
    } else if (_scrollController.offset <= 500 && _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = false;
      });
    }

    // Load more messages when reaching top
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      if (!messageProvider.isLoading && messageProvider.hasMoreMessages) {
        messageProvider.loadMessages();
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _sendImage(File(image.path));
    }
  }

  Future<void> _sendImage(File image) async {
    try {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      // Now pass file as a named parameter
      await messageProvider.sendFileMessage(file: image);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    }
  }

  Future<void> _pickDocument() async {
    // Implement document picking
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Consumer<MessageProvider>(
                  builder: (context, messageProvider, child) {
                    final messages = messageProvider.messages;

                    if (messageProvider.isLoading && messages.isEmpty) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.all(16),
                      itemCount:
                          messages.length + (messageProvider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (messageProvider.isLoading &&
                            index == messages.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final message = messages[index];
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        final isCurrentUser =
                            message.senderId == authProvider.user!.id;

                        // Add date headers
                        Widget dateHeader = SizedBox.shrink();
                        if (index == messages.length - 1 ||
                            !_isSameDay(messages[index].createdAt,
                                messages[index + 1].createdAt)) {
                          dateHeader = _buildDateHeader(message.createdAt);
                        }

                        return Column(
                          children: [
                            dateHeader,
                            MessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                              otherUser: widget.otherUser,
                              onLongPress: () =>
                                  _showMessageOptions(message, isCurrentUser),
                              onReactionTap: (emoji) =>
                                  _handleReaction(message, emoji),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      child: Icon(Icons.arrow_downward),
                      onPressed: _scrollToBottom,
                    ),
                  ),
              ],
            ),
          ),
          Consumer<MessageProvider>(
            builder: (context, messageProvider, _) {
              return MessageInput(
                message: messageProvider.messageBeingEdited,
                onSend: (content) {
                  if (messageProvider.messageBeingEdited != null) {
                    messageProvider.editMessage(
                      messageProvider.messageBeingEdited!.id,
                      content,
                    );
                  } else {
                    messageProvider.sendMessage(content);
                  }
                },
                onAttach: _showAttachmentOptions,
                onTypingStatusChanged: messageProvider.sendTypingStatus,
                onCancelEdit: messageProvider.cancelEditing,
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.otherUser['profilePicture'] != null
                ? NetworkImage(widget.otherUser['profilePicture'])
                : null,
            child: widget.otherUser['profilePicture'] == null
                ? Text(
                    '${widget.otherUser['firstName']?[0] ?? ''}',
                    style: TextStyle(
                      color: Colors.white,
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
                Text(
                  '${widget.otherUser['firstName'] ?? ''} ${widget.otherUser['lastName'] ?? ''}',
                  style: TextStyle(fontSize: 16),
                ),
                Consumer<MessageProvider>(
                  builder: (context, provider, _) {
                    if (provider.isTyping) {
                      return Text(
                        'Typing...',
                        style: TextStyle(fontSize: 12),
                      );
                    }
                    return Text(
                      widget.otherUser['role'] == 'doctor'
                          ? 'Doctor'
                          : 'Patient',
                      style: TextStyle(fontSize: 12),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            // Navigate to message search screen for this conversation
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            // Handle option selected
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view_profile',
              child: Text('View Profile'),
            ),
            PopupMenuItem(
              value: 'clear_chat',
              child: Text('Clear Chat'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          DateFormatter.formatMessageDate(date),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showMessageOptions(Message message, bool isCurrentUser) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser && message.messageType == 'text')
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  final provider =
                      Provider.of<MessageProvider>(context, listen: false);
                  provider.setMessageForEditing(message);
                },
              ),
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                // Implement reply functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.forward),
              title: Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _showForwardDialog(message);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              final provider =
                  Provider.of<MessageProvider>(context, listen: false);
              provider.deleteMessage(message.id);
            },
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(Message message) {
    // This would typically navigate to a user selection screen
    // For simplicity, we'll show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forward Message'),
        content: Text('Select a user to forward this message to.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _handleReaction(Message message, String emoji) {
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user!.id;

    // Check if user already reacted with this emoji
    if (message.hasUserReacted(userId, emoji)) {
      provider.removeReaction(message.id, emoji);
    } else {
      provider.addReaction(message.id, emoji);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}
