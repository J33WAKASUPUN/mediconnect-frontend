class Conversation {
  final String id;
  final dynamic participant; // Changed from List to a single participant
  final dynamic lastMessage;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participant,
    required this.lastMessage,
    required this.updatedAt,
    required this.metadata,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      participant: json['participant'] ?? {}, // Changed from participants to participant
      lastMessage: json['lastMessage'] ?? {},
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}