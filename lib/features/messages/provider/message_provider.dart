import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/socket_service.dart';
import 'package:mediconnect/core/services/auth_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService;
  final SocketService _socketService;
  final AuthService _authService;

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _hasMoreMessages = true;
  int _currentPage = 1;
  String? _currentConversationId;
  String? _otherUserId;
  Message? _messageBeingEdited;
  bool _isTyping = false;
  Map<String, dynamic>? _pagination;

  // Add these properties for unread count
  int _unreadMessageCount = 0;
  bool _initialized = false;

  MessageProvider({
    required MessageService messageService,
    required SocketService socketService,
    required AuthService authService,
  })  : _messageService = messageService,
        _socketService = socketService,
        _authService = authService;

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get hasMoreMessages => _hasMoreMessages;
  Message? get messageBeingEdited => _messageBeingEdited;
  bool get isTyping => _isTyping;
  String? get currentConversationId => _currentConversationId;

  // Add getter for totalUnreadCount
  int get totalUnreadCount => _unreadMessageCount;

  // Initialize provider and socket listeners
  Future<void> initialize() async {
    _socketService.onNewMessage.listen(_handleNewMessage);
    _socketService.onMessageEdited.listen(_handleMessageEdited);
    _socketService.onMessageRead.listen(_handleMessageRead);
    _socketService.onMessageReaction.listen(_handleMessageReaction);
    _socketService.onTyping.listen(_handleTypingStatus);

    // Fetch unread count, but handle errors
    try {
      _unreadMessageCount = await _messageService.getUnreadCount();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing message provider unread count: $e');
      _unreadMessageCount = 0; // Default to 0 on error
      _initialized = true; // Still mark as initialized
      notifyListeners();
    }
  }

  // Add method to refresh unread count
  Future<void> refreshUnreadCount() async {
    try {
      _unreadMessageCount = await _messageService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }

  Future<void> forceRefreshMessages() async {
    if (_currentConversationId == null) return;

    print('MessageProvider: Force refreshing messages');
    try {
      final result = await _messageService.getMessages(
        _currentConversationId!,
        page: 1, // Always get the first page
      );

      final List<dynamic> messageData = result['messages'] ?? [];
      List<Message> newMessages =
          messageData.map((data) => Message.fromJson(data)).toList();

      // Sort messages to ensure they're in chronological order (oldest to newest)
      newMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messages = newMessages;
      _currentPage = 2; // Set for next pagination
      _hasMoreMessages = newMessages.length >= (_pagination?['limit'] ?? 20);

      print(
          'MessageProvider: Forced refresh - got ${newMessages.length} messages');
      notifyListeners();
    } catch (e) {
      print('MessageProvider: Error in force refresh: $e');
    }
  }

  // Set the current conversation
  void setCurrentConversation(String conversationId, String otherUserId) {
    if (_currentConversationId != conversationId) {
      _messages = [];
      _currentPage = 1;
      _hasMoreMessages = true;
      _pagination = null;

      // Leave previous conversation if exists
      if (_currentConversationId != null) {
        _socketService.leaveConversation(_currentConversationId!);
      }

      _currentConversationId = conversationId;
      _otherUserId = otherUserId;

      // Join new conversation
      _socketService.joinConversation(conversationId);
      notifyListeners();
    }
  }

  // Load messages for current conversation
  Future<void> loadMessages({bool refresh = false}) async {
    if (_currentConversationId == null) return;

    if (refresh) {
      _currentPage = 1;
      _hasMoreMessages = true;
    }

    if (!_hasMoreMessages && !refresh) return;

    try {
      _isLoading = true;
      notifyListeners();

      print(
          'Loading messages for conversation: $_currentConversationId, page: $_currentPage');

      final result = await _messageService.getMessages(
        _currentConversationId!,
        page: _currentPage,
      );

      final List<dynamic> messageData = result['messages'] ?? [];
      List<Message> newMessages =
          messageData.map((data) => Message.fromJson(data)).toList();

      // Sort messages to ensure they're in chronological order (oldest to newest)
      newMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _pagination = result['pagination'];

      if (refresh) {
        _messages = newMessages;
      } else {
        // For pagination, we add older messages at the end of the list
        _messages = [...newMessages, ..._messages];
      }

      _hasMoreMessages = newMessages.length >= (_pagination?['limit'] ?? 20);

      if (_hasMoreMessages) {
        _currentPage++;
      }

      _isLoading = false;
      notifyListeners();

      // Mark messages as read
      _markMessagesAsRead();

      // Refresh unread count after marking messages as read
      await refreshUnreadCount();

      // Debug
      print('Current messages order:');
      _messages.forEach((m) => print('${m.createdAt.toLocal()}: ${m.content}'));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to load messages: $e');
    }
  }

  // Send a message
  Future<void> sendMessage(
    String content, {
    String messageType = 'text',
    String category = 'general',
    String priority = 'normal',
  }) async {
    if (_currentConversationId == null || _otherUserId == null) return;

    try {
      print(
          'MessageProvider: Sending message to $_otherUserId in conversation $_currentConversationId');

      final response = await _messageService.sendMessage(
        receiverId: _otherUserId!,
        content: content,
        category: category,
        priority: priority,
      );

      if (response['success'] == true && response['data'] != null) {
        // If socket doesn't deliver the message, add it directly
        final newMessage = Message.fromJson(response['data']);

        // Check if this message is already in our list (perhaps delivered via socket)
        final exists = _messages.any((m) => m.id == newMessage.id);

        if (!exists) {
          print('MessageProvider: Adding sent message directly to list');
          _messages = [..._messages, newMessage];
          notifyListeners();
        } else {
          print(
              'MessageProvider: Message already exists in list (likely from socket)');
        }
      } else {
        print(
            'MessageProvider: Failed to send message: ${response['message']}');
      }

      // Reset editing state if was editing
      if (_messageBeingEdited != null) {
        _messageBeingEdited = null;
        notifyListeners();
      }
    } catch (e) {
      print('MessageProvider: Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Send a file message
  Future<void> sendFileMessage({
    required File file,
    String category = 'general',
    String priority = 'normal',
  }) async {
    if (_currentConversationId == null || _otherUserId == null) return;

    try {
      await _messageService.sendFileMessage(
        receiverId: _otherUserId!,
        file: file,
        category: category,
        priority: priority,
      );
    } catch (e) {
      throw Exception('Failed to send file message: $e');
    }
  }

  // Edit a message
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      final response = await _messageService.editMessage(messageId, newContent);

      // Convert response to Message object
      if (response['success'] == true && response['data'] != null) {
        final updatedMessage = Message.fromJson(response['data']);

        // Update the message in the list
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = updatedMessage;
          notifyListeners();
        }
      }

      // Reset editing state
      _messageBeingEdited = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // Set a message for editing
  void setMessageForEditing(Message message) {
    _messageBeingEdited = message;
    notifyListeners();
  }

  // Cancel editing
  void cancelEditing() {
    _messageBeingEdited = null;
    notifyListeners();
  }

  // Add reaction to a message
  Future<void> addReaction(String messageId, String reaction) async {
    try {
      final response = await _messageService.addReaction(messageId, reaction);

      // Convert response to Message object
      if (response['success'] == true && response['data'] != null) {
        final updatedMessage = Message.fromJson(response['data']);

        // Update the message in the list
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = updatedMessage;
          notifyListeners();
        }
      }
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Remove reaction from a message
  Future<void> removeReaction(String messageId, String reaction) async {
    try {
      final response =
          await _messageService.removeReaction(messageId, reaction);

      // Convert response to Message object
      if (response['success'] == true && response['data'] != null) {
        final updatedMessage = Message.fromJson(response['data']);

        // Update the message in the list
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = updatedMessage;
          notifyListeners();
        }
      }
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // Forward a message
  Future<void> forwardMessage(String messageId, String receiverId) async {
    try {
      await _messageService.forwardMessage(messageId, receiverId);
    } catch (e) {
      throw Exception('Failed to forward message: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);

      // Remove from local list
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Search messages
  Future<List<Message>> searchMessages(String query,
      {String? conversationId}) async {
    try {
      final result = await _messageService.searchMessages(
        query,
        conversationId: conversationId,
      );

      final List<dynamic> messageData = result['messages'] ?? [];
      return messageData.map((data) => Message.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Send typing status
  void sendTypingStatus(bool isTyping) {
    if (_currentConversationId != null) {
      _socketService.sendTypingStatus(_currentConversationId!, isTyping);
    }
  }

  // Handle new message from socket
  void _handleNewMessage(Message message) {
    final currentUserId = _authService.currentUserId;

    print('MessageProvider: Received new message via socket:');
    print('  Message ID: ${message.id}');
    print('  Content: ${message.content}');
    print('  Sender: ${message.senderId}');
    print('  Receiver: ${message.receiverId}');
    print('  ConversationID: ${message.conversationId}');
    print('  Current ConversationID: $_currentConversationId');

    if (currentUserId == null) {
      print('MessageProvider: currentUserId is null in _handleNewMessage');
      return;
    }

    // Only add if for current conversation
    if (message.conversationId == _currentConversationId) {
      // Check if message already exists (might happen with our direct add in sendMessage)
      final exists = _messages.any((m) => m.id == message.id);

      if (!exists) {
        print('MessageProvider: Adding new message from socket to list');
        _messages = [..._messages, message];

        // Mark as read if from other user
        if (message.senderId != currentUserId) {
          _messageService.markMessageAsRead(message.id);
        }

        notifyListeners();
      } else {
        print(
            'MessageProvider: Message already exists in list - not adding duplicate');
      }
    } else if (message.receiverId == currentUserId) {
      // If message is for current user but not in current conversation, increment unread count
      _unreadMessageCount++;
      notifyListeners();
    }
  }

  // Handle message edit from socket
  void _handleMessageEdited(Map<String, dynamic> data) {
    final String messageId = data['messageId'];
    final String content = data['content'];

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      // Create a new message with updated content and edited flag
      final updatedMessage = Message(
        id: _messages[index].id,
        senderId: _messages[index].senderId,
        receiverId: _messages[index].receiverId,
        conversationId: _messages[index].conversationId,
        messageType: _messages[index].messageType,
        content: content,
        file: _messages[index].file,
        createdAt: _messages[index].createdAt,
        isEdited: true,
        editHistory: [
          ..._messages[index].editHistory,
          {
            'content': _messages[index].content,
            'editedAt': DateTime.now().toIso8601String()
          }
        ],
        reactions: _messages[index].reactions,
        forwardedFrom: _messages[index].forwardedFrom,
        metadata: _messages[index].metadata,
        deletedFor: _messages[index].deletedFor,
      );

      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  // Handle message read status from socket
  void _handleMessageRead(Map<String, dynamic> data) {
    print('MessageProvider: Handling message read event: $data');

    final String messageId = data['messageId'] ?? '';
    final String readAt = data['readAt'] ?? DateTime.now().toIso8601String();

    if (messageId.isEmpty) {
      print('MessageProvider: Invalid message ID in read receipt');
      return;
    }

    // Update all messages from this sender that were previously unread
    bool updated = false;
    final updatedMessages = _messages.map((message) {
      if (message.id == messageId) {
        print('MessageProvider: Marking message ${message.id} as read');
        final updatedMetadata = Map<String, dynamic>.from(message.metadata);
        updatedMetadata['status'] = 'read';
        updatedMetadata['readAt'] = readAt;

        updated = true;
        return Message(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          conversationId: message.conversationId,
          messageType: message.messageType,
          content: message.content,
          file: message.file,
          createdAt: message.createdAt,
          isEdited: message.isEdited,
          editHistory: message.editHistory,
          reactions: message.reactions,
          forwardedFrom: message.forwardedFrom,
          metadata: updatedMetadata,
          deletedFor: message.deletedFor,
        );
      }
      return message;
    }).toList();

    if (updated) {
      _messages = updatedMessages;
      notifyListeners();
      print('MessageProvider: Updated read status for message $messageId');
    }
  }

  // Handle reaction updates from socket
  void _handleMessageReaction(Map<String, dynamic> data) {
    final String messageId = data['messageId'];
    final String reaction = data['reaction'];
    final String userId = data['userId'];
    final bool added = data['added'];

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final updatedReactions = Map<String, List<Map<String, dynamic>>>.from(
          _messages[index].reactions);

      if (added) {
        // Add reaction
        if (!updatedReactions.containsKey(reaction)) {
          updatedReactions[reaction] = [];
        }

        if (!updatedReactions[reaction]!.any((r) => r['userId'] == userId)) {
          updatedReactions[reaction]!.add(
              {'userId': userId, 'addedAt': DateTime.now().toIso8601String()});
        }
      } else {
        // Remove reaction
        if (updatedReactions.containsKey(reaction)) {
          updatedReactions[reaction]!.removeWhere((r) => r['userId'] == userId);

          if (updatedReactions[reaction]!.isEmpty) {
            updatedReactions.remove(reaction);
          }
        }
      }

      _messages[index] = Message(
        id: _messages[index].id,
        senderId: _messages[index].senderId,
        receiverId: _messages[index].receiverId,
        conversationId: _messages[index].conversationId,
        messageType: _messages[index].messageType,
        content: _messages[index].content,
        file: _messages[index].file,
        createdAt: _messages[index].createdAt,
        isEdited: _messages[index].isEdited,
        editHistory: _messages[index].editHistory,
        reactions: updatedReactions,
        forwardedFrom: _messages[index].forwardedFrom,
        metadata: _messages[index].metadata,
        deletedFor: _messages[index].deletedFor,
      );

      notifyListeners();
    }
  }

  // Handle typing status from socket
  void _handleTypingStatus(Map<String, dynamic> data) {
    final String userId = data['userId'];
    final bool isTyping = data['isTyping'];

    // Only care if it's the other user in this conversation
    if (_otherUserId != null && userId == _otherUserId) {
      _isTyping = isTyping;
      notifyListeners();
    }
  }

  // Mark all unread messages as read
  Future<void> _markMessagesAsRead() async {
    if (_currentConversationId == null) return;

    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) return;

    final unreadMessages = _messages
        .where((m) =>
            m.receiverId == currentUserId && m.metadata['status'] != 'read')
        .toList();

    // If we found unread messages in current conversation
    if (unreadMessages.isNotEmpty) {
      // Update the unread count (decrease by the number of messages we're marking as read)
      _unreadMessageCount =
          math.max(0, _unreadMessageCount - unreadMessages.length);
      notifyListeners();
    }

    for (final message in unreadMessages) {
      try {
        await _messageService.markMessageAsRead(message.id);
      } catch (e) {
        print('Error marking message as read: $e');
      }
    }
  }

  // Mark messages as read when viewing
  Future<void> markVisibleMessagesAsRead() async {
    if (_currentConversationId == null) return;

    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) return;

    // Find unread messages received by current user
    final unreadMessages = _messages
        .where((m) =>
            m.receiverId == currentUserId &&
            m.senderId != currentUserId &&
            (m.metadata['status'] != 'read'))
        .toList();

    if (unreadMessages.isEmpty) return;

    print('MessageProvider: Marking ${unreadMessages.length} messages as read');

    // Mark each message as read
    for (final message in unreadMessages) {
      try {
        final response = await _messageService.markMessageAsRead(message.id);
        print(
            'MessageProvider: Marked message ${message.id} as read: $response');

        // Update the message in our list immediately
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          final updatedMetadata =
              Map<String, dynamic>.from(_messages[index].metadata);
          updatedMetadata['status'] = 'read';
          updatedMetadata['readAt'] = DateTime.now().toIso8601String();

          _messages[index] = Message(
            id: _messages[index].id,
            senderId: _messages[index].senderId,
            receiverId: _messages[index].receiverId,
            conversationId: _messages[index].conversationId,
            messageType: _messages[index].messageType,
            content: _messages[index].content,
            file: _messages[index].file,
            createdAt: _messages[index].createdAt,
            isEdited: _messages[index].isEdited,
            editHistory: _messages[index].editHistory,
            reactions: _messages[index].reactions,
            forwardedFrom: _messages[index].forwardedFrom,
            metadata: updatedMetadata,
            deletedFor: _messages[index].deletedFor,
          );
        }
      } catch (e) {
        print('MessageProvider: Error marking message as read: $e');
      }
    }

    // Update UI
    notifyListeners();

    // Update unread count
    await refreshUnreadCount();
  }

  // Clear data when changing conversations
  void clear() {
    if (_currentConversationId != null) {
      _socketService.leaveConversation(_currentConversationId!);
    }

    _messages = [];
    _currentPage = 1;
    _hasMoreMessages = true;
    _currentConversationId = null;
    _otherUserId = null;
    _messageBeingEdited = null;
    _isTyping = false;
    notifyListeners();
  }
}
