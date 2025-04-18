class PatientProfile {
  String? bloodType;
  List<String> medicalHistory;
  List<String> allergies;
  List<String> currentMedications;
  List<String> chronicConditions;
  List<EmergencyContact> emergencyContacts;
  InsuranceInfo? insuranceInfo;
  DateTime? lastCheckupDate;

  PatientProfile({
    this.bloodType,
    List<String>? medicalHistory,
    List<String>? allergies,
    List<String>? currentMedications,
    List<String>? chronicConditions,
    List<EmergencyContact>? emergencyContacts,
    this.insuranceInfo,
    this.lastCheckupDate,
  })  : medicalHistory = medicalHistory ?? [],
        allergies = allergies ?? [],
        currentMedications = currentMedications ?? [],
        chronicConditions = chronicConditions ?? [],
        emergencyContacts = emergencyContacts ?? [];

  // Improved helper method for parsing arrays
  static List<String> parseArray(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return List<String>.from(value.map((item) => item.toString()));
    }
    
    if (value is String) {
      // Handle strings like "[Asthma, Seasonal Allergies]"
      String processedStr = value.trim();
      if (processedStr.startsWith('[') && processedStr.endsWith(']')) {
        processedStr = processedStr.substring(1, processedStr.length - 1);
      }
      return processedStr.split(',').map((e) => e.trim()).toList();
    }
    
    return [];
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    try {
      print("Parsing PatientProfile from JSON: $json");
      
      return PatientProfile(
        bloodType: json['bloodType']?.toString(),
        medicalHistory: parseArray(json['medicalHistory']),
        allergies: parseArray(json['allergies']),
        currentMedications: parseArray(json['currentMedications']),
        chronicConditions: parseArray(json['chronicConditions']),
        emergencyContacts: json['emergencyContacts'] is List
            ? (json['emergencyContacts'] as List)
                .map((e) => EmergencyContact.fromJson(e))
                .toList()
            : [],
        insuranceInfo: json['insuranceInfo'] != null
            ? InsuranceInfo.fromJson(json['insuranceInfo'])
            : null,
        lastCheckupDate: json['lastCheckupDate'] != null
            ? DateTime.tryParse(json['lastCheckupDate'].toString())
            : null,
      );
    } catch (e) {
      print("Error in PatientProfile.fromJson: $e");
      // Return default profile instead of throwing error
      return PatientProfile();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'bloodType': bloodType,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'currentMedications': currentMedications,
      'chronicConditions': chronicConditions,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'insuranceInfo': insuranceInfo?.toJson(),
      'lastCheckupDate': lastCheckupDate?.toIso8601String(),
    };
  }

  PatientProfile clone() {
    return PatientProfile(
      bloodType: bloodType,
      medicalHistory: List.from(medicalHistory),
      allergies: List.from(allergies),
      currentMedications: List.from(currentMedications),
      chronicConditions: List.from(chronicConditions),
      emergencyContacts: emergencyContacts.map((e) => e.clone()).toList(),
      insuranceInfo: insuranceInfo?.clone(),
      lastCheckupDate: lastCheckupDate != null
          ? DateTime.fromMillisecondsSinceEpoch(
              lastCheckupDate!.millisecondsSinceEpoch)
          : null,
    );
  }
  
  @override
  String toString() {
    return 'PatientProfile(bloodType: $bloodType, medicalHistory: $medicalHistory, allergies: $allergies, medications: $currentMedications)';
  }
}

class DoctorProfile {
  String? specialization;
  String? licenseNumber;
  int? yearsOfExperience;
  List<Education> education;
  List<HospitalAffiliation> hospitalAffiliations;
  List<AvailableTimeSlot> availableTimeSlots;
  double? consultationFees;
  List<String> expertise;

  DoctorProfile({
    this.specialization,
    this.licenseNumber,
    this.yearsOfExperience,
    List<Education>? education,
    List<HospitalAffiliation>? hospitalAffiliations,
    List<AvailableTimeSlot>? availableTimeSlots,
    this.consultationFees,
    List<String>? expertise,
  })  : education = education ?? [],
        hospitalAffiliations = hospitalAffiliations ?? [],
        availableTimeSlots = availableTimeSlots ?? [],
        expertise = expertise ?? [];

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    try {
      return DoctorProfile(
        specialization: json['specialization']?.toString(),
        licenseNumber: json['licenseNumber']?.toString(),
        yearsOfExperience: json['yearsOfExperience'] != null 
            ? int.tryParse(json['yearsOfExperience'].toString()) 
            : null,
        education: json['education'] is List
            ? (json['education'] as List).map((e) => Education.fromJson(e)).toList()
            : [],
        hospitalAffiliations: json['hospitalAffiliations'] is List
            ? (json['hospitalAffiliations'] as List).map((e) => HospitalAffiliation.fromJson(e)).toList()
            : [],
        availableTimeSlots: json['availableTimeSlots'] is List
            ? (json['availableTimeSlots'] as List).map((e) => AvailableTimeSlot.fromJson(e)).toList()
            : [],
        consultationFees: json['consultationFees'] != null
            ? double.tryParse(json['consultationFees'].toString())
            : null,
        expertise: PatientProfile.parseArray(json['expertise']),
      );
    } catch (e) {
      print("Error in DoctorProfile.fromJson: $e");
      return DoctorProfile();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'education': education.map((e) => e.toJson()).toList(),
      'hospitalAffiliations':
          hospitalAffiliations.map((e) => e.toJson()).toList(),
      'availableTimeSlots':
          availableTimeSlots.map((e) => e.toJson()).toList(),
      'consultationFees': consultationFees,
      'expertise': expertise,
    };
  }

  DoctorProfile clone() {
    return DoctorProfile(
      specialization: specialization,
      licenseNumber: licenseNumber,
      yearsOfExperience: yearsOfExperience,
      education: education.map((e) => e.clone()).toList(),
      hospitalAffiliations:
          hospitalAffiliations.map((e) => e.clone()).toList(),
      availableTimeSlots:
          availableTimeSlots.map((e) => e.clone()).toList(),
      consultationFees: consultationFees,
      expertise: List.from(expertise),
    );
  }
}

class EmergencyContact {
  String name;
  String relationship;
  String phone;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
    };
  }

  EmergencyContact clone() {
    return EmergencyContact(
      name: name,
      relationship: relationship,
      phone: phone,
    );
  }
}

class InsuranceInfo {
  String? provider;
  String? policyNumber;
  DateTime? expiryDate;

  InsuranceInfo({
    this.provider,
    this.policyNumber,
    this.expiryDate,
  });

  factory InsuranceInfo.fromJson(Map<String, dynamic> json) {
    return InsuranceInfo(
      provider: json['provider']?.toString(),
      policyNumber: json['policyNumber']?.toString(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'policyNumber': policyNumber,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  InsuranceInfo clone() {
    return InsuranceInfo(
      provider: provider,
      policyNumber: policyNumber,
      expiryDate: expiryDate != null
          ? DateTime.fromMillisecondsSinceEpoch(
              expiryDate!.millisecondsSinceEpoch)
          : null,
    );
  }
}

class Education {
  String degree;
  String institution;
  int year;

  Education({
    required this.degree,
    required this.institution,
    required this.year,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree']?.toString() ?? '',
      institution: json['institution']?.toString() ?? '',
      year: json['year'] != null ? int.tryParse(json['year'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'year': year,
    };
  }

  Education clone() {
    return Education(
      degree: degree,
      institution: institution,
      year: year,
    );
  }
}

class HospitalAffiliation {
  String hospitalName;
  String role;
  DateTime startDate;

  HospitalAffiliation({
    required this.hospitalName,
    required this.role,
    required this.startDate,
  });

  factory HospitalAffiliation.fromJson(Map<String, dynamic> json) {
    return HospitalAffiliation(
      hospitalName: json['hospitalName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      startDate: json['startDate'] != null 
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hospitalName': hospitalName,
      'role': role,
      'startDate': startDate.toIso8601String(),
    };
  }

  HospitalAffiliation clone() {
    return HospitalAffiliation(
      hospitalName: hospitalName,
      role: role,
      startDate: DateTime.fromMillisecondsSinceEpoch(
          startDate.millisecondsSinceEpoch),
    );
  }
}

class AvailableTimeSlot {
  String day;
  List<TimeSlot> slots;

  AvailableTimeSlot({
    required this.day,
    List<TimeSlot>? slots,
  }) : slots = slots ?? [];

  factory AvailableTimeSlot.fromJson(Map<String, dynamic> json) {
    return AvailableTimeSlot(
      day: json['day']?.toString() ?? '',
      slots: json['slots'] is List
          ? (json['slots'] as List).map((e) => TimeSlot.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'slots': slots.map((e) => e.toJson()).toList(),
    };
  }

  AvailableTimeSlot clone() {
    return AvailableTimeSlot(
      day: day,
      slots: slots.map((e) => e.clone()).toList(),
    );
  }
}

class TimeSlot {
  String startTime;
  String endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  TimeSlot clone() {
    return TimeSlot(
      startTime: startTime,
      endTime: endTime,
    );
  }
}