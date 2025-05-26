import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mediconnect/core/models/health_ai_model.dart';
import 'package:mediconnect/core/services/health_ai_service.dart';

class HealthAIProvider with ChangeNotifier {
  final HealthAIService _service;

  List<HealthSession> _sessions = [];
  HealthSession? _currentSession;
  List<HealthMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  List<String> _sampleTopics = [];
  bool _isAnalyzingImage = false;

  HealthAIProvider(this._service);

  // Getters
  List<HealthSession> get sessions => _sessions;
  HealthSession? get currentSession => _currentSession;
  List<HealthMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isAnalyzingImage => _isAnalyzingImage;
  String? get error => _error;
  List<String> get sampleTopics => _sampleTopics;

  // Load all sessions
  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _service.getSessions();
      _sessions.sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt)); // Sort by most recent
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new session
  Future<HealthSession?> createSession({String userType = 'patient'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newSession = await _service.createSession(userType: userType);
      _currentSession = newSession;
      _messages = [];

      // Add to sessions list and sort
      _sessions.add(newSession);
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _isLoading = false;
      notifyListeners();
      return newSession;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Load a specific session
  Future<void> loadSession(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getSession(sessionId);
      _currentSession = data['session'] as HealthSession;
      _messages = data['messages'] as List<HealthMessage>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a session
  Future<bool> deleteSession(String sessionId) async {
    try {
      final result = await _service.deleteSession(sessionId);

      if (result) {
        // Remove from local list
        _sessions.removeWhere((session) => session.id == sessionId);

        // If current session was deleted, clear it
        if (_currentSession?.id == sessionId) {
          _currentSession = null;
          _messages = [];
        }

        notifyListeners();
      }

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send a message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _currentSession == null) return;

    final sessionId = _currentSession!.id;

    // Optimistically add user message to UI
    final userMessage = HealthMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );

    _messages = [..._messages, userMessage];
    notifyListeners();

    // Add loading message
    final loadingMessage = HealthMessage.loading(sessionId);
    _messages = [..._messages, loadingMessage];
    notifyListeners();

    try {
      final result = await _service.sendMessage(sessionId, content);

      // Remove loading message
      _messages.removeWhere((msg) => msg.isLoading);

      // Add assistant response
      final assistantMessage = result['assistantMessage'] as HealthMessage;
      _messages = [..._messages, assistantMessage];

      // Update session data if it changed
      await loadSessions();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      // Remove loading message
      _messages.removeWhere((msg) => msg.isLoading);
      // Add error message
      _messages = [..._messages, HealthMessage.error(sessionId, e.toString())];
      notifyListeners();
    }
  }

  // Analyze medical image
  Future<String?> analyzeImage(dynamic file, {String? prompt}) async {
    _isAnalyzingImage = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.analyzeImage(file, prompt: prompt);

      // If successful, refresh the messages to get the latest from backend
      if (_currentSession != null) {
        // Update sessions list to reflect any changes
        await loadSessions();

        // Reload current session to get the latest messages
        if (_currentSession != null) {
          await loadSession(_currentSession!.id);
        }
      }

      _isAnalyzingImage = false;
      notifyListeners();
      return result['analysis'];
    } catch (e) {
      _error = e.toString();
      _isAnalyzingImage = false;
      notifyListeners();

      if (_currentSession != null) {
        // Reload session to get latest messages
        await loadSession(_currentSession!.id);
      }

      return null;
    }
  }

  // Load sample topics
  Future<void> loadSampleTopics() async {
    try {
      _sampleTopics = await _service.getSampleTopics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
