import 'package:flutter/material.dart';
import 'package:mediconnect/core/services/medication_reminder_service.dart';
import '../../../core/models/medication_reminder_model.dart';
import '../../../core/models/medical_record_model.dart';

class MedicationReminderProvider with ChangeNotifier {
  // Direct instance - no singleton
  final _reminderService = SimpleMedicationReminderService();
  List<MedicationReminder> _reminders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<MedicationReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load medication reminders from records
  Future<void> loadMedicationsFromRecords(List<MedicalRecord> records) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Extract all prescriptions from records
      final List<Prescription> prescriptions = [];
      for (final record in records) {
        prescriptions.addAll(record.prescriptions);
      }
      
      // Convert prescriptions to reminders
      final List<MedicationReminder> newReminders = [];
      for (int i = 0; i < prescriptions.length; i++) {
        final prescription = prescriptions[i];
        final reminder = MedicationReminder.fromPrescription(
          'prescription_$i', // Generate an ID
          prescription.medicine,
          prescription.dosage,
          prescription.frequency,
        );
        
        // Check if reminder is already active
        reminder.isActive = await _reminderService.isReminderActive(reminder.id);
        
        newReminders.add(reminder);
      }
      
      _reminders = newReminders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading medication reminders: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle reminder status
  Future<void> toggleReminder(MedicationReminder reminder) async {
    try {
      final bool isActive = await _reminderService.toggleReminder(
        medicationId: reminder.id,
        medicationName: reminder.medicationName,
        dosage: reminder.dosage,
      );
      
      // Update reminder status in UI
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index].isActive = isActive;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling reminder: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
}