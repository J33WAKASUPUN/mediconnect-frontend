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
  Timer? _reconnectTimer;
  
  // Stream controllers for real-time events
  final _connectionStateController = StreamController<bool>.broadcast();
  final _newMessageController = StreamController<Message>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageEditedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReactionController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream getters
  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<Message> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<Map<String, dynamic>> get onMessageEdited => _messageEditedController.stream;
  Stream<Map<String, dynamic>> get onMessageReaction => _messageReactionController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  
  // Initialize socket connection
  void initialize(String token) {
    print("[SocketService] Initializing with token: ${token.substring(0, 10)}...");
    
    // Store token for reconnection
    _token = token;
    
    // Clean up existing socket
    if (_socket != null) {
      print("[SocketService] Disconnecting existing socket");
      _socket!.disconnect();
      _socket = null;
    }
    
    // Cancel reconnect timer
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }

    try {
      // Ensure URL has correct protocol
      String baseUrl = ApiEndpoints.baseUrl;
      if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
        baseUrl = 'http://$baseUrl';
      }
      
      print("[SocketService] Connecting to: $baseUrl");
      
      // IMPORTANT: These options MUST match your server's expectations
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
          .setTransports(['websocket'])  // Only use WebSocket transport
          .disableAutoConnect()          // Manual connection
          .setAuth({'token': token})     // Auth with token as your server expects
          .build()
      );
      
      // Set up event listeners
      _setupEventListeners();
      
      // Connect
      _socket!.connect();
      print("[SocketService] Connection attempt started");
      
      // Default to disconnected state until connection confirmed
      _connectionStateController.add(false);
      
    } catch (e) {
      print("[SocketService] Error initializing socket: $e");
      isConnected = false;
      _connectionStateController.add(false);
    }
  }
  
  void _setupEventListeners() {
    if (_socket == null) return;
    
    // Connection events
    _socket!.onConnect((_) {
      print("[SocketService] Connected successfully!");
      isConnected = true;
      _connectionStateController.add(true);
    });
    
    _socket!.onConnectError((error) {
      print("[SocketService] Connection error: $error");
      isConnected = false;
      _connectionStateController.add(false);
      _startReconnectTimer();
    });
    
    _socket!.onDisconnect((_) {
      print("[SocketService] Disconnected");
      isConnected = false;
      _connectionStateController.add(false);
    });
    
    // Debug all events
    _socket!.onAny((event, data) {
      print("[SocketService] Event: $event, Data: $data");
    });
    
    // Message events
    _socket!.on('newMessage', (data) {
      print("[SocketService] New message received");
      try {
        final message = Message.fromJson(data);
        _newMessageController.add(message);
      } catch (e) {
        print("[SocketService] Error parsing message: $e");
      }
    });
    
    _socket!.on('messageRead', (data) {
      _messageReadController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('messageEdited', (data) {
      _messageEditedController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('messageReaction', (data) {
      _messageReactionController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('userTyping', (data) {
      _typingController.add(Map<String, dynamic>.from(data));
    });
  }
  
  void _startReconnectTimer() {
    if (_reconnectTimer != null) return;
    
    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (timer.tick > 3) { // Try 3 times then give up
        timer.cancel();
        _reconnectTimer = null;
        return;
      }
      
      if (_token != null && _socket != null) {
        print("[SocketService] Attempting to reconnect... (${timer.tick}/3)");
        _socket!.connect();
      }
    });
  }
  
  void joinConversation(String conversationId) {
    if (_socket == null || !isConnected) {
      print("[SocketService] Cannot join conversation - not connected");
      return;
    }
    
    _socket!.emit('joinConversation', conversationId);
  }
  
  void leaveConversation(String conversationId) {
    if (_socket == null || !isConnected) {
      print("[SocketService] Cannot leave conversation - not connected");
      return;
    }
    
    _socket!.emit('leaveConversation', conversationId);
  }
  
  void sendTypingStatus(String conversationId, bool isTyping) {
    if (_socket == null || !isConnected) {
      print("[SocketService] Cannot send typing status - not connected");
      return;
    }
    
    _socket!.emit('typing', {'conversationId': conversationId, 'isTyping': isTyping});
  }
  
  bool hasConnection() {
    return _socket != null && isConnected;
  }
  
  void reconnect() {
    if (_token == null) return;
    
    initialize(_token!);
  }
  
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
    }
    
    isConnected = false;
    _connectionStateController.add(false);
  }
  
  void dispose() {
    disconnect();
    
    _connectionStateController.close();
    _newMessageController.close();
    _messageReadController.close();
    _messageEditedController.close();
    _messageReactionController.close();
    _typingController.close();
  }
  
  // For testing only
  void emitEvent(String eventName, Map<String, dynamic> data) {
    if (_socket != null && isConnected) {
      _socket!.emit(eventName, data);
    }
  }
}