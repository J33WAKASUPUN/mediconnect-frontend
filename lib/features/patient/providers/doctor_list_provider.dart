import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class DoctorListProvider with ChangeNotifier {
  final ApiService _apiService;
  List<User> _doctors = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _currentSpecialty = '';
  String _sortBy = 'name'; // 'name', 'specialty', 'experience'

  DoctorListProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  List<User> get doctors => _sortAndFilterDoctors();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentSpecialty => _currentSpecialty;
  String get sortBy => _sortBy;

  // Initialize
  Future<void> initialize() async {
    if (_doctors.isEmpty) {
      await loadDoctors();
    }
  }

  // Filter and sort doctors
  List<User> _sortAndFilterDoctors() {
    List<User> filteredDoctors = _doctors.where((doctor) {
      final matchesSearch = 
        doctor.firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        doctor.lastName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (doctor.doctorProfile?.specialization?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesSpecialty = _currentSpecialty.isEmpty || 
        doctor.doctorProfile?.specialization?.toLowerCase() == _currentSpecialty.toLowerCase();

      return matchesSearch && matchesSpecialty;
    }).toList();

    // Sort the filtered list
    switch (_sortBy) {
      case 'name':
        filteredDoctors.sort((a, b) => 
          '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}'));
        break;
      case 'specialty':
        filteredDoctors.sort((a, b) => 
          (a.doctorProfile?.specialization ?? '').compareTo(b.doctorProfile?.specialization ?? ''));
        break;
      case 'experience':
        filteredDoctors.sort((a, b) => 
          (b.doctorProfile?.yearsOfExperience ?? 0).compareTo(a.doctorProfile?.yearsOfExperience ?? 0));
        break;
    }

    return filteredDoctors;
  }

  // Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Specialty filter
  void setSpecialtyFilter(String specialty) {
    _currentSpecialty = specialty;
    notifyListeners();
  }

  // Sorting
  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  // Load doctors
  Future<void> loadDoctors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Verify API connection first
      final isConnected = await _apiService.verifyApiConnection();
      if (!isConnected) {
        throw 'Could not connect to the API';
      }

      final response = await _apiService.getAllDoctors();
      print('Doctors response length: ${response.length}');
      print('First doctor data: ${response.firstOrNull}');

      _doctors = response.map((json) {
        try {
          return User.fromJson(json);
        } catch (e) {
          print('Error parsing doctor data: $e');
          print('Problematic JSON: $json');
          return null;
        }
      }).whereType<User>().toList();

      print('Successfully loaded ${_doctors.length} doctors');
    } catch (e) {
      print('Error in loadDoctors: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh doctors list
  Future<void> refresh() async {
    _searchQuery = '';
    _currentSpecialty = '';
    _sortBy = 'name';
    await loadDoctors();
  }
}