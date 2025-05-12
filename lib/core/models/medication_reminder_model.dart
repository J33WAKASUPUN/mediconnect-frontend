class MedicationReminder {
  final String id;
  final String medicationName;
  final String dosage;
  final String frequency;
  final List<String> times; // Times in 24-hour format, e.g., ["08:00", "20:00"]
  bool isActive;

  MedicationReminder({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.isActive = false,
  });
  
  // Create reminder from a prescription
  factory MedicationReminder.fromPrescription(
    String prescriptionId, 
    String medicine, 
    String dosage, 
    String frequency
  ) {
    // Parse times from frequency (simplified)
    List<String> times = [];
    
    if (frequency.toLowerCase().contains('morning') || 
        frequency.toLowerCase().contains('daily')) {
      times.add('08:00');
    }
    
    if (frequency.toLowerCase().contains('afternoon')) {
      times.add('14:00');
    }
    
    if (frequency.toLowerCase().contains('evening') || 
        frequency.toLowerCase().contains('night')) {
      times.add('20:00');
    }
    
    if (frequency.toLowerCase().contains('twice daily') || 
        frequency.toLowerCase().contains('2 times')) {
      if (times.isEmpty) {
        times = ['08:00', '20:00'];
      }
    }
    
    if (frequency.toLowerCase().contains('three times') ||
        frequency.toLowerCase().contains('3 times')) {
      times = ['08:00', '14:00', '20:00'];
    }
    
    // Ensure we have at least one time
    if (times.isEmpty) {
      times = ['09:00'];
    }
    
    return MedicationReminder(
      id: prescriptionId,
      medicationName: medicine,
      dosage: dosage,
      frequency: frequency,
      times: times,
    );
  }
}