import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/socket_service.dart';
import 'package:mediconnect/core/utils/date_formatter.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/provider/message_provider.dart';
import 'package:mediconnect/features/messages/widgets/document_picker.dart';
import 'package:mediconnect/features/messages/widgets/message_bubble.dart';
import 'package:mediconnect/features/messages/widgets/message_input.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _keyboardListenerNode = FocusNode();

  bool _showScrollToBottom = false;
  bool _isInitialized = false;
  Timer? _refreshTimer;
  bool _isActive = true;

  // Multi-select variables
  bool _isInSelectionMode = false;
  List<String> _selectedMessageIds = [];

  // Common reaction emojis
  final List<String> _reactionEmojis = ['👍', '❤️', '😮', '😢', '👏', '🙏'];

  @override
  void initState() {
    super.initState();
    _setupProviders();
    _scrollController.addListener(_scrollListener);
    _startPeriodicRefresh();

    // Mark visible messages as read immediately and periodically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });

    // Set up periodic read status update
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted && _isActive) {
        _markMessagesAsRead();
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  void _markMessagesAsRead() {
    if (mounted) {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      messageProvider.markVisibleMessagesAsRead();
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted && _isActive) {
        final socketService =
            Provider.of<SocketService>(context, listen: false);
        final messageProvider =
            Provider.of<MessageProvider>(context, listen: false);

        // Only force refresh if socket is not connected
        if (!socketService.hasConnection()) {
          print('ChatDetailScreen: Socket not connected, refreshing messages');
          messageProvider.forceRefreshMessages();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isActive = true;

    // Force refresh when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final messageProvider =
            Provider.of<MessageProvider>(context, listen: false);
        messageProvider.forceRefreshMessages();
      }
    });
  }

  @override
  void deactivate() {
    _isActive = false;
    super.deactivate();
  }

  @override
  void dispose() {
    // Cancel the refresh timer
    _refreshTimer?.cancel();

    // Leave the conversation
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.leaveConversation(widget.conversationId);

    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _keyboardListenerNode.dispose();
    super.dispose();
  }

  void _setupProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);

      // Ensure the ID is correct
      final otherUserId = widget.otherUser['_id'] ?? widget.otherUser['id'];

      if (otherUserId != null) {
        // Set current conversation
        messageProvider.setCurrentConversation(
          widget.conversationId,
          otherUserId,
        );

        // Load messages
        messageProvider.loadMessages(refresh: true).then((_) {
          setState(() {
            _isInitialized = true;
          });

          // Scroll to bottom after loading messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not identify the other user')),
        );
      }
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // Show scroll to bottom button when not at bottom
    if (_scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 200 &&
        !_showScrollToBottom) {
      setState(() {
        _showScrollToBottom = true;
      });
    } else if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = false;
      });
    }

    // Load more messages when scrolling to top
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      if (!messageProvider.isLoading && messageProvider.hasMoreMessages) {
        messageProvider.loadMessages().then((_) {
          // Maintain scroll position after loading more messages
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(100);
          }
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sending image...')),
          );
        }

        // Use the image directly without converting to File for web compatibility
        await _sendFileWithUploader(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _sendFileWithUploader(dynamic file) async {
    try {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);

      // Handle the case where we're passing a custom file object from document picker
      if (file is Map && file.containsKey('bytes')) {
        // For web document files from FilePicker
        await messageProvider.sendWebFileBytes(
          bytes: file['bytes'],
          fileName: file['name'],
          mimeType: file['mimeType'],
        );
      } else {
        // For XFile objects from image picker
        await messageProvider.sendWebSafeFile(file: file);
      }

      // Scroll to bottom after sending a message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      }
    }
  }

  String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _sendFile(File file) async {
    try {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.sendFileMessage(file: file);

      // Scroll to bottom after sending a message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final pickedDocument = await DocumentPicker.pickDocument(context);

      if (pickedDocument != null && pickedDocument.isValid) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sending document...')),
          );
        }

        // Handle the document based on platform
        if (kIsWeb && pickedDocument.bytes != null) {
          // For web with bytes
          await _handleWebDocument(pickedDocument);
        } else if (pickedDocument.file != null) {
          // For mobile with file
          await _sendFile(pickedDocument.file!);
        } else {
          throw Exception('Invalid document data for current platform');
        }
      }
    } catch (e) {
      print('Error picking document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick document: $e')),
        );
      }
    }
  }

  Future<void> _handleWebDocument(PickedDocument document) async {
    try {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);

      // Send the document bytes
      await messageProvider.sendWebFileBytes(
        bytes: document.bytes!,
        fileName: document.name,
        mimeType: document.mimeType,
      );

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send document: $e')),
        );
      }
    }
  }

  Future<void> _sendDocument(File file) async {
    try {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.sendFileMessage(file: file);

      // Scroll to bottom after sending a message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send document: $e')),
        );
      }
    }
  }

  // Selection mode methods
  void _enterSelectionMode(String messageId) {
    setState(() {
      _isInSelectionMode = true;
      _selectedMessageIds = [messageId];
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isInSelectionMode = false;
      _selectedMessageIds = [];
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _exitSelectionMode();
        }
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  bool _isSelected(String messageId) {
    return _selectedMessageIds.contains(messageId);
  }

  // Method to select all messages (both yours and the other user's)
  void _selectAllMessages() {
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);

    setState(() {
      _selectedMessageIds = messageProvider.messages.map((m) => m.id).toList();
    });
  }

  // Method to select only your messages
  void _selectOnlyMyMessages() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    if (currentUserId == null) return;

    setState(() {
      _selectedMessageIds = messageProvider.messages
          .where((m) => m.senderId == currentUserId)
          .map((m) => m.id)
          .toList();
    });
  }

  // Method to select only the other user's messages
  void _selectOtherUserMessages() {
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    final otherUserId = widget.otherUser['_id'] ?? widget.otherUser['id'];

    if (otherUserId == null) return;

    setState(() {
      _selectedMessageIds = messageProvider.messages
          .where((m) => m.senderId == otherUserId)
          .map((m) => m.id)
          .toList();
    });
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    final count = _selectedMessageIds.length;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Messages'),
        content: Text(
            'Delete ${count == 1 ? 'this message' : 'these $count messages'}?'),
        actions: [
          TextButton(
            child: Text('CANCEL'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete each selected message
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      List<Future<void>> deleteFutures = [];

      for (final messageId in _selectedMessageIds) {
        deleteFutures.add(messageProvider.deleteMessage(messageId));
      }

      await Future.wait(deleteFutures);

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${count == 1 ? 'Message' : '$count messages'} deleted'),
          ),
        );
      }

      // Exit selection mode
      _exitSelectionMode();
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting messages: $e'),
          ),
        );
      }
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat'),
        content: Text(
            'Are you sure you want to delete all messages in this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            child: Text('CANCEL'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'CLEAR',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Clear chat logic - for now we'll just select and delete all messages
                final messageProvider =
                    Provider.of<MessageProvider>(context, listen: false);
                setState(() {
                  _selectedMessageIds =
                      messageProvider.messages.map((m) => m.id).toList();
                });
                await _deleteSelectedMessages();

                // Close loading indicator
                if (mounted) Navigator.pop(context);

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat cleared'),
                    ),
                  );
                }

                _exitSelectionMode();
              } catch (e) {
                // Close loading indicator
                if (mounted) Navigator.pop(context);

                // Show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing chat: $e'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Method to show WhatsApp-style reaction popup
  void _showReactionPopup(
      BuildContext context, Message message, bool isCurrentUser) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - 60, // Position above the message
        position.dx + size.width,
        position.dy,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            height: 50,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _reactionEmojis.map((emoji) {
                final isSelected = message.hasUserReacted(
                  Provider.of<AuthProvider>(context, listen: false).user!.id,
                  emoji,
                );

                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _handleReaction(message, emoji);
                  },
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Add quick action buttons below the emojis
        PopupMenuItem(
          height: 40,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (isCurrentUser && message.messageType == 'text')
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(context);
                    final messageProvider =
                        Provider.of<MessageProvider>(context, listen: false);
                    messageProvider.setMessageForEditing(message);
                  },
                  tooltip: 'Edit',
                ),
              IconButton(
                icon: Icon(Icons.reply, color: Colors.blue),
                onPressed: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
                tooltip: 'Reply',
              ),
              IconButton(
                icon: Icon(Icons.forward, color: Colors.green),
                onPressed: () {
                  Navigator.pop(context);
                  _showForwardDialog(message);
                },
                tooltip: 'Forward',
              ),
              if (isCurrentUser)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteDialog(message);
                  },
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _replyToMessage(Message message) {
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    messageProvider.setReplyMessage(message);
  }

  void _showForwardDialog(Message message) {
    // Implementation will be added later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forward functionality will be implemented soon')),
    );
  }

  void _showDeleteDialog(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete message
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.deleteMessage(message.id);

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: const Text('Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppColors.primary),
              title: const Text('Document'),
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
  Widget build(BuildContext context) {
    final Widget screenContent = Container(
      decoration: BoxDecoration(
        // Light pattern background
        color: Colors.grey[100],
        image: DecorationImage(
          image: AssetImage('assets/images/chat_background.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.2, // Subtle background
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Consumer<MessageProvider>(
                  builder: (context, messageProvider, child) {
                    if (messageProvider.isLoading && !_isInitialized) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }

                    // Get messages in chronological order (oldest first)
                    final messages = messageProvider.messages;

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Say hi to start the conversation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group messages by date
                    Map<String, List<Message>> messagesByDate = {};
                    for (var message in messages) {
                      final date = DateFormatter.formatMessageDate(
                          message.createdAt.toLocal());
                      if (!messagesByDate.containsKey(date)) {
                        messagesByDate[date] = [];
                      }
                      messagesByDate[date]!.add(message);
                    }

                    // Build a list of widgets with date headers and messages
                    List<Widget> messageWidgets = [];

                    // Add loading indicator at the top if loading more messages
                    if (messageProvider.isLoading) {
                      messageWidgets.add(
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                        ),
                      );
                    }

                    // Process each date group
                    messagesByDate.forEach((date, messagesForDate) {
                      // Add date header
                      messageWidgets.add(
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              date,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );

                      // Add messages for this date
                      for (var message in messagesForDate) {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        final isCurrentUser =
                            message.senderId == authProvider.user?.id;

                        // Check if message is selected
                        final isSelected = _isSelected(message.id);

                        // Create the bubble with selection support
                        Widget messageWidget = _buildMessageBubble(
                          message,
                          isCurrentUser,
                          isSelected,
                        );

                        messageWidgets.add(messageWidget);
                      }
                    });

                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: messageWidgets,
                    );
                  },
                ),
                if (_showScrollToBottom && !_isInSelectionMode)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: AppColors.primary,
                      onPressed: _scrollToBottom,
                      child:
                          const Icon(Icons.arrow_downward, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          if (!_isInSelectionMode)
            Consumer<MessageProvider>(
              builder: (context, messageProvider, _) {
                return MessageInput(
                  message: messageProvider.messageBeingEdited,
                  replyToMessage: messageProvider.replyToMessage,
                  otherUser: widget.otherUser,
                  onSend: (content) async {
                    if (messageProvider.messageBeingEdited != null) {
                      await messageProvider.editMessage(
                        messageProvider.messageBeingEdited!.id,
                        content,
                      );
                    } else if (messageProvider.replyToMessage != null) {
                      await messageProvider.sendMessageWithReply(content);
                    } else {
                      await messageProvider.sendMessage(content);
                    }

                    // Scroll to bottom after sending a message
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  },
                  onAttach: _showAttachmentOptions,
                  onTypingStatusChanged: messageProvider.sendTypingStatus,
                  onCancelEdit: messageProvider.cancelEditing,
                  onCancelReply: messageProvider.cancelReply,
                );
              },
            ),
        ],
      ),
    );

    // For web, wrap with keyboard listener for shortcuts
    if (kIsWeb) {
      return RawKeyboardListener(
        focusNode: _keyboardListenerNode,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            final messageProvider =
                Provider.of<MessageProvider>(context, listen: false);
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final currentUserId = authProvider.user?.id;

            // Find user's messages
            final userMessages = messageProvider.messages
                .where((m) => m.senderId == currentUserId)
                .toList();

            if (userMessages.isEmpty) return;

            // Get the most recent message
            final latestMessage = userMessages.last;

            // Edit with Ctrl+E or Cmd+E
            if ((event.isControlPressed || event.isMetaPressed) &&
                event.logicalKey == LogicalKeyboardKey.keyE) {
              if (latestMessage.messageType == 'text') {
                messageProvider.setMessageForEditing(latestMessage);
              }
            }

            // Delete with Ctrl+D or Cmd+D
            if ((event.isControlPressed || event.isMetaPressed) &&
                event.logicalKey == LogicalKeyboardKey.keyD) {
              _showDeleteDialog(latestMessage);
            }
          }
        },
        child: Scaffold(
          appBar: _isInSelectionMode ? _buildSelectionAppBar() : _buildAppBar(),
          body: screenContent,
        ),
      );
    } else {
      return Scaffold(
        appBar: _isInSelectionMode ? _buildSelectionAppBar() : _buildAppBar(),
        body: screenContent,
      );
    }
  }

  // Helper method to build message bubble with selection support
  Widget _buildMessageBubble(
      Message message, bool isCurrentUser, bool isSelected) {
    return Builder(
      builder: (context) {
        Widget bubble = Stack(
          children: [
            GestureDetector(
              // Single tap to show reactions popup
              onTap: _isInSelectionMode
                  ? () => _toggleMessageSelection(message.id)
                  : () => _showReactionPopup(context, message, isCurrentUser),
              child: MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                otherUser: widget.otherUser,
                isSelected: isSelected,
                onLongPress: _isInSelectionMode
                    ? () => _toggleMessageSelection(message.id)
                    : () => _enterSelectionMode(message.id),
                onReactionTap: (emoji) => _handleReaction(message, emoji),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: isCurrentUser ? 0 : null,
                left: isCurrentUser ? null : 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        );

        // In selection mode, we need another wrapper to handle taps
        if (_isInSelectionMode) {
          return GestureDetector(
            onTap: () => _toggleMessageSelection(message.id),
            onLongPress: null,
            child: bubble,
          );
        }

        return bubble;
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      titleSpacing: 0,
      elevation: 0,
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.3),
              backgroundImage: widget.otherUser['profilePicture'] != null
                  ? NetworkImage(widget.otherUser['profilePicture'])
                  : null,
              child: widget.otherUser['profilePicture'] == null
                  ? Text(
                      '${widget.otherUser['firstName']?[0] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser['role'] == 'doctor'
                      ? 'Dr. ${widget.otherUser['firstName'] ?? ''} ${widget.otherUser['lastName'] ?? ''}'
                      : '${widget.otherUser['firstName'] ?? ''} ${widget.otherUser['lastName'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Consumer<MessageProvider>(
                  builder: (context, provider, _) {
                    if (provider.isTyping) {
                      return const Text(
                        'Typing...',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      );
                    }
                    return Text(
                      widget.otherUser['role'] == 'doctor'
                          ? widget.otherUser['specialty'] ?? 'Doctor'
                          : 'Patient',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
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
          icon: const Icon(Icons.search, color: Colors.white, size: 20),
          onPressed: () {
            // Navigate to message search screen for this conversation
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: Icon(Icons.select_all, color: AppColors.primary),
                      title: Text('Select messages',
                          style: TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        _enterSelectionMode(
                          Provider.of<MessageProvider>(context, listen: false)
                              .messages
                              .first
                              .id,
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.person, color: AppColors.primary),
                      title:
                          Text('View profile', style: TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        // Implement view profile
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_sweep, color: Colors.red),
                      title: Text('Clear chat', style: TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        _showClearChatDialog();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Build selection mode app bar with options to select all, select my messages, or select other user's messages
  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedMessageIds.length} selected',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white, size: 20),
          onPressed:
              _selectedMessageIds.isEmpty ? null : _deleteSelectedMessages,
          tooltip: 'Delete selected',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white, size: 20),
          onSelected: (value) {
            if (value == 'select_all') {
              _selectAllMessages();
            } else if (value == 'select_my') {
              _selectOnlyMyMessages();
            } else if (value == 'select_other') {
              _selectOtherUserMessages();
            } else if (value == 'unselect_all') {
              _exitSelectionMode();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select_all',
              child: ListTile(
                leading:
                    Icon(Icons.select_all, color: AppColors.primary, size: 18),
                title:
                    Text('Select all messages', style: TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'select_my',
              child: ListTile(
                leading: Icon(Icons.person, color: AppColors.primary, size: 18),
                title: Text('Select only my messages',
                    style: TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'select_other',
              child: ListTile(
                leading: Icon(Icons.person_outline,
                    color: AppColors.primary, size: 18),
                title: Text('Select only their messages',
                    style: TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'unselect_all',
              child: ListTile(
                leading:
                    Icon(Icons.deselect, color: AppColors.primary, size: 18),
                title: Text('Unselect all', style: TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// class SocketStatusWidget extends StatefulWidget {
//   const SocketStatusWidget({Key? key}) : super(key: key);

//   @override
//   State<SocketStatusWidget> createState() => _SocketStatusWidgetState();
// }

// class _SocketStatusWidgetState extends State<SocketStatusWidget> {
//   bool _reconnecting = false;

//   @override
//   Widget build(BuildContext context) {
//     final socketService = Provider.of<SocketService>(context, listen: false);

//     return StreamBuilder<bool>(
//       stream: socketService.connectionState,
//       initialData: socketService.hasConnection(),
//       builder: (context, snapshot) {
//         final connected = snapshot.data ?? false;

//         return GestureDetector(
//           onTap: () {
//             if (!connected && !_reconnecting) {
//               setState(() {
//                 _reconnecting = true;
//               });

//               final authProvider =
//                   Provider.of<AuthProvider>(context, listen: false);
//               if (authProvider.token != null) {
//                 socketService.reconnect();

//                 ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Attempting to reconnect...')));

//                 // Reset reconnecting state after a delay
//                 Future.delayed(Duration(seconds: 5), () {
//                   if (mounted) {
//                     setState(() {
//                       _reconnecting = false;
//                     });
//                   }
//                 });
//               }
//             }
//           },
//           child: Container(
//             width: double.infinity,
//             padding: EdgeInsets.symmetric(vertical: 2),
//             color: connected
//                 ? Colors.green.withOpacity(0.1)
//                 : Colors.red.withOpacity(0.1),
//             child: Center(
//               child: _reconnecting
//                   ? Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         SizedBox(
//                           width: 10,
//                           height: 10,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(Colors.amber),
//                           ),
//                         ),
//                         SizedBox(width: 6),
//                         Text(
//                           'Reconnecting...',
//                           style: TextStyle(
//                             color: Colors.amber,
//                             fontSize: 10,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     )
//                   : Text(
//                       connected
//                           ? 'Chat sync connected'
//                           : 'Chat sync offline - Tap to reconnect',
//                       style: TextStyle(
//                         color: connected ? Colors.green : Colors.red,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
