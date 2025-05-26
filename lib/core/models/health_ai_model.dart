import 'package:intl/intl.dart';

class HealthSession {
  final String id;
  final String title;
  final String userType;
  final String lastMessagePreview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  HealthSession({
    required this.id,
    required this.title,
    required this.userType,
    this.lastMessagePreview = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory HealthSession.fromJson(Map<String, dynamic> json) {
    return HealthSession(
      id: json['_id'],
      title: json['title'] ?? 'New Conversation',
      userType: json['userType'] ?? 'patient',
      lastMessagePreview: json['lastMessagePreview'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);

    if (dateToCheck == today) {
      return 'Today, ${DateFormat('hh:mm a').format(updatedAt)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(updatedAt)}';
    } else if (now.difference(dateToCheck).inDays < 7) {
      return DateFormat('EEEE, hh:mm a').format(updatedAt);
    } else {
      return DateFormat('MMM dd, yyyy').format(updatedAt);
    }
  }
}

class HealthMessage {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final DateTime createdAt;
  final TokenUsage? tokenUsage;
  final bool isLoading;
  final bool isError;

  HealthMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.tokenUsage,
    this.isLoading = false,
    this.isError = false,
  });

  factory HealthMessage.fromJson(Map<String, dynamic> json) {
    return HealthMessage(
      id: json['_id'],
      sessionId: json['sessionId'],
      role: json['role'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      tokenUsage: json['tokenUsage'] != null 
          ? TokenUsage.fromJson(json['tokenUsage']) 
          : null,
    );
  }

  // Create a loading placeholder message
  factory HealthMessage.loading(String sessionId) {
    return HealthMessage(
      id: 'loading-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      role: 'assistant',
      content: '...',
      createdAt: DateTime.now(),
      isLoading: true,
    );
  }

  // Create an error message
  factory HealthMessage.error(String sessionId, String errorMessage) {
    return HealthMessage(
      id: 'error-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      role: 'system',
      content: 'Error: $errorMessage',
      createdAt: DateTime.now(),
      isError: true,
    );
  }
}

class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  TokenUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
    );
  }
}