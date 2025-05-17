import 'dart:async';
import 'package:mediconnect/core/models/message.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mediconnect/config/api_endpoints.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool isConnected = false;
  String? _token;
  
  // Stream controllers for real-time events
  final _newMessageController = StreamController<Message>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageEditedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReactionController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream getters
  Stream<Message> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<Map<String, dynamic>> get onMessageEdited => _messageEditedController.stream;
  Stream<Map<String, dynamic>> get onMessageReaction => _messageReactionController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  
  // Initialize socket connection
  void initialize(String token) {
    if (_socket != null) {
      _socket!.disconnect();
    }

    _token = token;
    
    _socket = IO.io(ApiEndpoints.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token}
    });
    
    _socket!.connect();
    
    _socket!.on('connect', (_) {
      isConnected = true;
      print('Socket connected');
    });
    
    _socket!.on('disconnect', (_) {
      isConnected = false;
      print('Socket disconnected');
    });
    
    // Listen for message events
    _socket!.on('newMessage', (data) {
      try {
        if (data['message'] != null) {
          final message = Message.fromJson(data['message']);
          _newMessageController.add(message);
        }
      } catch (e) {
        print('Error parsing new message: $e');
      }
    });
    
    _socket!.on('messageRead', (data) {
      _messageReadController.add(data);
    });
    
    _socket!.on('messageEdited', (data) {
      _messageEditedController.add(data);
    });
    
    _socket!.on('messageReaction', (data) {
      _messageReactionController.add(data);
    });
    
    _socket!.on('userTyping', (data) {
      _typingController.add(data);
    });
  }
  
  // Join a conversation room
  void joinConversation(String conversationId) {
    if (isConnected && _socket != null) {
      _socket!.emit('joinConversation', conversationId);
    }
  }
  
  // Leave a conversation room
  void leaveConversation(String conversationId) {
    if (isConnected && _socket != null) {
      _socket!.emit('leaveConversation', conversationId);
    }
  }
  
  // Send typing indicator
  void sendTypingStatus(String conversationId, bool isTyping) {
    if (isConnected && _socket != null) {
      _socket!.emit('typing', {'conversationId': conversationId, 'isTyping': isTyping});
    }
  }
  
  // Set token (for reconnection)
  void setToken(String token) {
    if (_token != token) {
      _token = token;
      if (_socket != null) {
        _socket!.disconnect();
        initialize(token);
      }
    }
  }
  
  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      isConnected = false;
    }
  }
  
  // Clean up resources
  void dispose() {
    _newMessageController.close();
    _messageReadController.close();
    _messageEditedController.close();
    _messageReactionController.close();
    _typingController.close();
    disconnect();
  }
}