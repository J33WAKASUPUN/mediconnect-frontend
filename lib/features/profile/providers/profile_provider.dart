// profile_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart'; // Make sure to import this

class ProfileProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider; // Added AuthProvider
  bool _isLoading = false;
  String? _error;
  
  PatientProfile? _patientProfile;
  DoctorProfile? _doctorProfile;
  DateTime _lastUpdated = DateTime.now().toUtc();

  ProfileProvider({
    required ApiService apiService,
    required AuthProvider authProvider, // Added parameter
  }) : _apiService = apiService,
       _authProvider = authProvider; // Initialize AuthProvider

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  PatientProfile? get patientProfile => _patientProfile;
  DoctorProfile? get doctorProfile => _doctorProfile;
  DateTime get lastUpdated => _lastUpdated;

  // Get profile data
  Future<void> getProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getProfile();
      
      print("API Response: $response");
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Update user information in AuthProvider
        _authProvider.updateUserFromProfile(data);
        
        print("Patient Profile Data: ${data['patientProfile']}");
        
        if (data['patientProfile'] != null) {
          try {
            print("Parsing PatientProfile from JSON: ${data['patientProfile']}");
            _patientProfile = PatientProfile.fromJson(data['patientProfile']);
            print("Successfully parsed patient profile: $_patientProfile");
            print("Blood Type: ${_patientProfile?.bloodType}");
            print("Medical History: ${_patientProfile?.medicalHistory}");
            print("Allergies: ${_patientProfile?.allergies}");
          } catch (e) {
            print("Error parsing patient profile: $e");
            _error = "Error parsing profile data: $e";
            _patientProfile = PatientProfile(); // Provide default profile instead of null
          }
        } else {
          _patientProfile = null;
        }
        
        if (data['doctorProfile'] != null) {
          try {
            _doctorProfile = DoctorProfile.fromJson(data['doctorProfile']);
          } catch (e) {
            print("Error parsing doctor profile: $e");
            _doctorProfile = DoctorProfile(); // Provide default profile instead of null
          }
        } else {
          _doctorProfile = null;
        }
        
        _lastUpdated = DateTime.now().toUtc();
      } else {
        throw 'Failed to load profile data';
      }
      
      notifyListeners(); // Make sure to notify after setting profiles
    } catch (e) {
      print("Error in getProfile: $e");
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update basic profile
  Future<void> updateBasicProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    File? profilePicture,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.updateBasicProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        address: address,
        profilePicture: profilePicture,
      );

      await getProfile(); // Refresh profile data
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update patient profile
  Future<void> updatePatientProfile(PatientProfile profile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.updatePatientProfile(
        bloodType: profile.bloodType,
        medicalHistory: profile.medicalHistory,
        allergies: profile.allergies,
        currentMedications: profile.currentMedications,
        chronicConditions: profile.chronicConditions,
        emergencyContacts: profile.emergencyContacts
            .map((contact) => contact.toJson())
            .toList(),
        insuranceInfo: profile.insuranceInfo?.toJson(),
      );

      await getProfile(); // Refresh profile data
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update doctor profile
  Future<void> updateDoctorProfile(DoctorProfile profile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.updateDoctorProfile(
        specialization: profile.specialization,
        licenseNumber: profile.licenseNumber,
        yearsOfExperience: profile.yearsOfExperience,
        education: profile.education
            .map((edu) => edu.toJson())
            .toList(),
        hospitalAffiliations: profile.hospitalAffiliations
            .map((aff) => aff.toJson())
            .toList(),
        availableTimeSlots: profile.availableTimeSlots
            .map((slot) => slot.toJson())
            .toList(),
        consultationFees: profile.consultationFees,
        expertise: profile.expertise,
      );

      await getProfile(); // Refresh profile data
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}