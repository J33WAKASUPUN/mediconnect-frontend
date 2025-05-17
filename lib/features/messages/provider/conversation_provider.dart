import 'package:flutter/foundation.dart';
import 'package:mediconnect/core/models/conversation.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/auth_service.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/socket_service.dart';

class ConversationProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();
  
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  int _totalUnread = 0;
  
  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  int get totalUnread => _totalUnread;
  
  // Initialize provider and socket listeners
  Future<void> initialize() async {
    // Initialize socket listeners
    _socketService.onNewMessage.listen(_handleNewMessage);
    _socketService.onMessageRead.listen(_handleMessageRead);
  }
  
  // Load conversations
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _conversations = (await _messageService.getConversations()).cast<Conversation>();
      await _updateUnreadCount();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to load conversations: $e');
    }
  }
  
  // Update unread count
  Future<void> _updateUnreadCount() async {
    try {
      _totalUnread = await _messageService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error updating unread count: $e');
    }
  }
  
  // Handle new message from socket
  void _handleNewMessage(Message message) {
    final currentUserId = _authService.currentUserId;
    
    // Only handle if this is for current user
    if (message.senderId != currentUserId && message.receiverId != currentUserId) return;
    
    // Find conversation or create new one
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == message.conversationId
    );
    
    if (conversationIndex != -1) {
      // Update existing conversation
      final conversation = _conversations[conversationIndex];
      
      // Update with new last message
      _conversations[conversationIndex] = Conversation(
        id: conversation.id,
        participants: conversation.participants,
        lastMessage: message,
        updatedAt: DateTime.now(),
        metadata: conversation.metadata,
        unreadCount: message.senderId != currentUserId ? 
          conversation.unreadCount + 1 : conversation.unreadCount,
      );
      
      // Move conversation to top
      _conversations.removeAt(conversationIndex);
      _conversations.insert(0, _conversations[conversationIndex]);
    } else {
      // New conversation will be fetched on next loadConversations
      loadConversations();
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
      (c) => c.lastMessage != null && c.lastMessage['_id'] == messageId
    );
    
    if (conversationIndex != -1) {
      // Update read status of last message if this user is the sender
      if (_conversations[conversationIndex].lastMessage['senderId'] == currentUserId) {
        final updatedLastMessage = Map<String, dynamic>.from(_conversations[conversationIndex].lastMessage);
        
        if (updatedLastMessage['metadata'] != null) {
          updatedLastMessage['metadata']['status'] = 'read';
          updatedLastMessage['metadata']['readAt'] = data['readAt'];
        }
        
        _conversations[conversationIndex] = Conversation(
          id: _conversations[conversationIndex].id,
          participants: _conversations[conversationIndex].participants,
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
        participants: _conversations[index].participants,
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
      final otherParticipant = conversation.participants.firstWhere(
        (p) => p['_id'] != _authService.currentUserId,
        orElse: () => {},
      );
      
      if (otherParticipant.isEmpty) return false;
      
      final firstName = otherParticipant['firstName'] ?? '';
      final lastName = otherParticipant['lastName'] ?? '';
      final fullName = '$firstName $lastName'.toLowerCase();
      
      return fullName.contains(query.toLowerCase());
    }).toList();
  }
}