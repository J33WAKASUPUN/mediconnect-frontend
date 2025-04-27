// auth_provider.dart
import 'dart:io';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as js;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error
}

@JS('getAuthToken')
external String? _jsGetAuthToken();

@JS('localStorage.removeItem')
external void _jsRemoveItem(String key);

@JS('localStorage.removeItem')
external void _jsRemoveLocalStorageItem(String key);

@JS('saveAuthToken')
external void _jsSaveAuthToken(String token);

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthProvider({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService {
    _init();
  }

  // State
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _error;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating;

  // Initialize auth state
  Future<void> _init() async {
    // Check secure storage first
    _token = _storageService.getToken();
    _user = _storageService.getUser();

    // For web, also check localStorage if secure storage is empty
    if (kIsWeb && (_token == null || _user == null)) {
      try {
        final webToken = _jsGetAuthToken();
        if (webToken != null && webToken.isNotEmpty) {
          print("Found token in localStorage");

          // Try to verify the token
          _apiService.setAuthToken(webToken);
          try {
            final profileResponse = await _apiService.getProfile();
            if (profileResponse != null && profileResponse['user'] != null) {
              // Token is valid, set up the user
              _token = webToken;
              _user = User.fromJson(profileResponse['user']);

              // Also save to secure storage
              await _storageService.saveToken(_token!);
              await _storageService.saveUser(_user!);
            }
          } catch (e) {
            print("Error verifying web token: $e");
            // Failed to verify token, clear it
            _jsRemoveItem('auth_token');
          }
        }
      } catch (e) {
        print("Error checking localStorage: $e");
      }
    }

    // Set final auth status
    if (_token != null && _user != null) {
      _apiService.setAuthToken(_token!);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

// LOGOUT
  Future<void> logout() async {
  await _storageService.clearAll();

  if (kIsWeb) {
    // Clear localStorage in web
    try {
      _jsRemoveLocalStorageItem('auth_token');
    } catch (e) {
      print("Error clearing localStorage: $e");
    }
  }

  _token = null;
  _user = null;
  _status = AuthStatus.unauthenticated;
  notifyListeners();
}

  // Register
  Future<void> register({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String gender,
    required String address,
    File? profilePicture,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _error = null;
      notifyListeners();

      final response = await _apiService.register(
        email: email,
        password: password,
        role: role,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        gender: gender,
        address: address,
        profilePicture: profilePicture,
      );

      _token = response['token'];
      _user = User.fromJson(response['user']);

      await _storageService.saveToken(_token!);
      await _storageService.saveUser(_user!);

      _apiService.setAuthToken(_token!);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _error = null;
      notifyListeners();

      // Call the API
      final response = await _apiService.login(
        email: email,
        password: password,
        role: role,
      );

      // Extract token and user
      _token = response['token'];
      _user = User.fromJson(response['user']);

      // Save to storage service
      await _storageService.saveToken(_token!);
      await _storageService.saveUser(_user!);

      // For web platforms, also save to localStorage
      if (kIsWeb) {
        try {
          _jsSaveAuthToken(_token!);
        } catch (e) {
          print("Error saving to localStorage: $e");
        }
      }

      _apiService.setAuthToken(_token!);
      _status = AuthStatus.authenticated;
      notifyListeners();

      return response; // Return the response for web credential saving
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get initial route based on auth status and role
  String getInitialRoute() {
    if (_status != AuthStatus.authenticated) return '/login';
    return _user?.role == 'patient'
        ? '/patient/dashboard'
        : '/doctor/dashboard';
  }

  void updateUserFromProfile(Map<String, dynamic> userData) {
    if (_user != null) {
      try {
        // Create a new User object with updated information
        _user = User(
          id: userData['_id']?.toString() ?? _user!.id,
          username: userData['username']?.toString() ?? _user!.username,
          role: userData['role']?.toString() ?? _user!.role,
          firstName: userData['firstName']?.toString() ?? _user!.firstName,
          lastName: userData['lastName']?.toString() ?? _user!.lastName,
          email: userData['email']?.toString() ?? _user!.email,
          phoneNumber:
              userData['phoneNumber']?.toString() ?? _user!.phoneNumber,
          gender: userData['gender']?.toString() ?? _user!.gender,
          address: userData['address']?.toString() ?? _user!.address,
          profilePicture:
              userData['profilePicture']?.toString() ?? _user!.profilePicture,
          createdAt: userData['createdAt']?.toString() ?? _user!.createdAt,
        );

        _storageService.saveUser(_user!);

        print(
            "Updated user in AuthProvider: firstName=${_user!.firstName}, lastName=${_user!.lastName}, email=${_user!.email}");
        notifyListeners();
      } catch (e) {
        print("Error updating user from profile: $e");
      }
    }
  }
}
