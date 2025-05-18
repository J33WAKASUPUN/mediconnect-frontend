import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/socket_service.dart';
import 'package:mediconnect/core/utils/date_formatter.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/provider/message_provider.dart';
import 'package:mediconnect/features/messages/screens/socket_test_screen.dart';
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
  bool _isInitialized = false;

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

  Timer? _refreshTimer;
  bool _isActive = true;

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
      await messageProvider.sendFileMessage(file: image);

      // Scroll to bottom after sending a message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
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
                    if (messageProvider.isLoading && !_isInitialized) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // Get messages in chronological order (oldest first)
                    final messages = messageProvider.messages;

                    if (messages.isEmpty) {
                      return Center(child: Text('No messages yet'));
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
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    // Process each date group
                    messagesByDate.forEach((date, messagesForDate) {
                      // Add date header
                      messageWidgets.add(
                        Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              date,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
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

                        messageWidgets.add(
                          MessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            otherUser: widget.otherUser,
                            onLongPress: () =>
                                _showMessageOptions(message, isCurrentUser),
                            onReactionTap: (emoji) =>
                                _handleReaction(message, emoji),
                          ),
                        );
                      }
                    });

                    return ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      children: messageWidgets,
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
                onSend: (content) async {
                  if (messageProvider.messageBeingEdited != null) {
                    await messageProvider.editMessage(
                      messageProvider.messageBeingEdited!.id,
                      content,
                    );
                  } else {
                    await messageProvider.sendMessage(content);

                    // Scroll to bottom after sending a message
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }
                },
                onAttach: _showAttachmentOptions,
                onTypingStatusChanged: messageProvider.sendTypingStatus,
                onCancelEdit: messageProvider.cancelEditing,
              );
            },
          ),
          // SocketStatusWidget(),
        ],
      ),
    );
  }

  // The rest of your methods remain the same
  PreferredSizeWidget _buildAppBar() {
    // Your existing implementation
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
        // IconButton(
        //   icon: Icon(Icons.bug_report),
        //   onPressed: () {
        //     Navigator.of(context).pushNamed(SocketTestScreen.routeName);
        //   },
        // ),
        PopupMenuButton<String>(
          onSelected: (value) {
            // Handle option selected
          },
          itemBuilder: (context) => [
            // PopupMenuItem(
            //   value: 'socket_test',
            //   child: Text('Socket Test Tool'),
            // ),
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

  void _showMessageOptions(Message message, bool isCurrentUser) {
    // Your existing implementation
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
    // Your existing implementation
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
    // Your existing implementation
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
    // Your existing implementation
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
    // Your existing implementation
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
