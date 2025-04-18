import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class DoctorProvider with ChangeNotifier {
  // ignore: unused_field
  final ApiService _apiService;
  User? _doctorProfile;
  bool _isLoading = false;
  String? _error;

  DoctorProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  User? get doctorProfile => _doctorProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get doctor profile
  Future<void> getDoctorProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement API call to get doctor profile
      // This will be implemented when we add the backend endpoint

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update timestamp helper
  String getCurrentTimestamp() {
    return '2025-03-08 14:35:24'; // Using the provided timestamp format
  }
}
