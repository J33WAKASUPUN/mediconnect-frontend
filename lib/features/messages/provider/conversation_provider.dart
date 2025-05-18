import 'package:flutter/foundation.dart';
import 'package:mediconnect/core/models/conversation.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/auth_service.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/socket_service.dart';

class ConversationProvider with ChangeNotifier {
  final MessageService _messageService;
  final AuthService _authService;
  final SocketService _socketService;

  ConversationProvider({
    required MessageService messageService,
    required AuthService authService,
    required SocketService socketService,
  })  : _messageService = messageService,
        _authService = authService,
        _socketService = socketService;

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  int _totalUnread = 0;
  bool _hasError = false;
  String? _errorMessage;

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  int get totalUnread => _totalUnread;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  // Initialize provider and socket listeners
  Future<void> initialize() async {
    try {
      // Initialize socket listeners
      _socketService.onNewMessage.listen(_handleNewMessage);
      _socketService.onMessageRead.listen(_handleMessageRead);

      // Don't automatically load conversations here
      // Let the UI call loadConversations when ready
    } catch (e) {
      print('Error initializing ConversationProvider: $e');
      _hasError = true;
      _errorMessage = e.toString();
    }
  }

  // Load conversations
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      notifyListeners();

      print("ConversationProvider: Starting to load conversations");

      // Check token
      final token = _authService.currentToken;
      print(
          "ConversationProvider: Using token: ${token != null ? 'yes' : 'no'}");

      // Get the raw data from the service
      final rawConversations = await _messageService.getConversations();
      print(
          "ConversationProvider: Got ${rawConversations.length} conversations from API");

      // Print the first conversation for debugging
      if (rawConversations.isNotEmpty) {
        print(
            "ConversationProvider: Sample conversation structure: ${rawConversations[0]}");
      }

      // Convert to Conversation objects
      _conversations = rawConversations.map((data) {
        try {
          return Conversation.fromJson(data);
        } catch (e) {
          print("Error converting conversation: $e");
          return Conversation(
            id: data['_id'] ?? 'unknown',
            participant: data['participant'] ?? {},
            lastMessage: data['lastMessage'] ?? {},
            updatedAt: DateTime.now(),
            metadata: {},
            unreadCount: 0,
          );
        }
      }).toList();

      print(
          "ConversationProvider: Converted ${_conversations.length} conversations");

      // Update unread count safely
      try {
        _totalUnread = await _messageService.getUnreadCount();
        print("ConversationProvider: Total unread: $_totalUnread");
      } catch (e) {
        // If unread count API fails, calculate from conversations
        print('Error getting unread count, calculating from conversations: $e');
        _totalUnread =
            _conversations.fold(0, (sum, convo) => sum + convo.unreadCount);
        print("ConversationProvider: Calculated unread: $_totalUnread");
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("ConversationProvider: Error loading conversations: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear errors
  void clearErrors() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // The rest of your methods remain largely unchanged...

  // Handle new message from socket
  void _handleNewMessage(Message message) {
    final currentUserId = _authService.currentUserId;

    // Only handle if currentUserId is available
    if (currentUserId == null) {
      print('ConversationProvider: currentUserId is null');
      return;
    }

    // Only handle if this is for current user
    if (message.senderId != currentUserId &&
        message.receiverId != currentUserId) return;

    // Find conversation or create new one
    final conversationIndex =
        _conversations.indexWhere((c) => c.id == message.conversationId);

    if (conversationIndex != -1) {
      // Update existing conversation
      final conversation = _conversations[conversationIndex];

      // Create updated conversation
      final updatedConversation = Conversation(
        id: conversation.id,
        participant: conversation.participant,
        lastMessage: message,
        updatedAt: DateTime.now(),
        metadata: conversation.metadata,
        unreadCount: message.senderId != currentUserId
            ? conversation.unreadCount + 1
            : conversation.unreadCount,
      );

      // Remove old conversation
      _conversations.removeAt(conversationIndex);

      // Add updated conversation at the beginning
      _conversations.insert(0, updatedConversation);
    } else {
      // New conversation will be fetched on next loadConversations
      loadConversations();
      return;
    }

    // Update total unread
    if (message.senderId != currentUserId) {
      _totalUnread++;
    }

    notifyListeners();
  }

  // Handle message read status from socket
  void _handleMessageRead(Map<String, dynamic> data) {
    final currentUserId = _authService.currentUserId;
    final String messageId = data['messageId'];

    // Find conversation with this message as last message
    final conversationIndex = _conversations.indexWhere(
        (c) => c.lastMessage != null && c.lastMessage['_id'] == messageId);

    if (conversationIndex != -1) {
      // Update read status of last message if this user is the sender
      if (_conversations[conversationIndex].lastMessage['senderId'] ==
          currentUserId) {
        final updatedLastMessage = Map<String, dynamic>.from(
            _conversations[conversationIndex].lastMessage);

        if (updatedLastMessage['metadata'] != null) {
          updatedLastMessage['metadata']['status'] = 'read';
          updatedLastMessage['metadata']['readAt'] = data['readAt'];
        }

        _conversations[conversationIndex] = Conversation(
          id: _conversations[conversationIndex].id,
          participant: _conversations[conversationIndex].participant,
          lastMessage: updatedLastMessage,
          updatedAt: _conversations[conversationIndex].updatedAt,
          metadata: _conversations[conversationIndex].metadata,
          unreadCount: _conversations[conversationIndex].unreadCount,
        );

        notifyListeners();
      }
    }
  }

  // Reset unread count for a conversation
  void resetUnreadCount(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);

    if (index != -1) {
      final unreadCount = _conversations[index].unreadCount;
      _totalUnread -= unreadCount;

      _conversations[index] = Conversation(
        id: _conversations[index].id,
        participant: _conversations[index].participant,
        lastMessage: _conversations[index].lastMessage,
        updatedAt: _conversations[index].updatedAt,
        metadata: _conversations[index].metadata,
        unreadCount: 0,
      );

      notifyListeners();
    }
  }

  // Search conversations by user name
  List<Conversation> searchConversations(String query) {
    if (query.isEmpty) return _conversations;

    return _conversations.where((conversation) {
      final otherParticipant = conversation.participant;

      if (otherParticipant == null || otherParticipant is! Map) return false;

      final firstName = otherParticipant['firstName'] ?? '';
      final lastName = otherParticipant['lastName'] ?? '';
      final fullName = '$firstName $lastName'.toLowerCase();

      return fullName.contains(query.toLowerCase());
    }).toList();
  }
}
