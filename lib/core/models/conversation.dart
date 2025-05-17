class Conversation {
  final String id;
  final List<dynamic> participants;
  final dynamic lastMessage;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.updatedAt,
    required this.metadata,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      participants: json['participants'] ?? [],
      lastMessage: json['lastMessage'],
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
      metadata: json['metadata'] != null 
        ? Map<String, dynamic>.from(json['metadata']) 
        : {},
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}