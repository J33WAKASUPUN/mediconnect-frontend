import 'dart:convert';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String conversationId;
  final String messageType;
  final String? content;
  final Map<String, dynamic>? file;
  final DateTime createdAt;
  final bool isEdited;
  final List<Map<String, dynamic>> editHistory;
  final Map<String, List<Map<String, dynamic>>> reactions;
  final Map<String, dynamic>? forwardedFrom;
  final Map<String, dynamic> metadata;
  final List<String> deletedFor;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.messageType,
    this.content,
    this.file,
    required this.createdAt,
    this.isEdited = false,
    this.editHistory = const [],
    this.reactions = const {},
    this.forwardedFrom,
    required this.metadata,
    this.deletedFor = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle reactions map conversion
    Map<String, List<Map<String, dynamic>>> reactionsMap = {};
    if (json['reactions'] != null) {
      Map<String, dynamic> rawReactions =
          Map<String, dynamic>.from(json['reactions']);
      rawReactions.forEach((emoji, users) {
        if (users is List) {
          reactionsMap[emoji] = List<Map<String, dynamic>>.from(users);
        }
      });
    }

    // Improved metadata handling
    Map<String, dynamic> metadataMap = {};
    if (json['metadata'] != null) {
      if (json['metadata'] is String) {
        // If metadata is a JSON string, parse it
        try {
          metadataMap = Map<String, dynamic>.from(jsonDecode(json['metadata']));
          print('Parsed metadata from string: $metadataMap');
        } catch (e) {
          print('Error parsing metadata string: $e');
          // Fallback to empty map if parsing fails
          metadataMap = {};
        }
      } else if (json['metadata'] is Map) {
        // If metadata is already a Map, convert it to the right type
        metadataMap = Map<String, dynamic>.from(json['metadata']);
        print('Converted metadata from Map: $metadataMap');
      }
    }

    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      conversationId: json['conversationId'] ?? '',
      messageType: json['messageType'] ?? 'text',
      content: json['content'],
      file:
          json['file'] != null ? Map<String, dynamic>.from(json['file']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isEdited: json['isEdited'] ?? false,
      editHistory: json['editHistory'] != null
          ? List<Map<String, dynamic>>.from(json['editHistory'])
          : [],
      reactions: reactionsMap,
      forwardedFrom: json['forwardedFrom'] != null
          ? Map<String, dynamic>.from(json['forwardedFrom'])
          : null,
      metadata: metadataMap, // Use the improved metadata handling here
      deletedFor: json['deletedFor'] != null
          ? List<String>.from(json['deletedFor'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'messageType': messageType,
      'content': content,
      'file': file,
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
      'editHistory': editHistory,
      'reactions': reactions,
      'forwardedFrom': forwardedFrom,
      'metadata': metadata,
      'deletedFor': deletedFor,
    };
  }

  // Helper method to check if message has reactions
  bool get hasReactions => reactions.isNotEmpty;

  // Helper method to check if current user has reacted
  bool hasUserReacted(String userId, String emoji) {
    if (!reactions.containsKey(emoji)) return false;
    return reactions[emoji]!.any((reaction) => reaction['userId'] == userId);
  }
}
