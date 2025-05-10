class CalendarTimeSlot {
  final String? id;
  final String startTime;
  final String endTime;
  final bool isBooked;
  final bool isBlocked;

  CalendarTimeSlot({
    this.id,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.isBlocked = false,
  });

  factory CalendarTimeSlot.fromJson(Map<String, dynamic> json) {
    return CalendarTimeSlot(
      id: json['_id'],
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isBooked: json['isBooked'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      'isBlocked': isBlocked,
    };
  }
}

class DaySchedule {
  final String? id;
  final DateTime date;
  final List<CalendarTimeSlot> slots;
  final bool isHoliday;
  final String? holidayReason;

  DaySchedule({
    this.id,
    required this.date,
    required this.slots,
    this.isHoliday = false,
    this.holidayReason,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    List<dynamic> slotsList = json['slots'] ?? [];
    return DaySchedule(
      id: json['_id'],
      date: DateTime.parse(json['date']),
      slots: slotsList.map((slot) => CalendarTimeSlot.fromJson(slot)).toList(),
      isHoliday: json['isHoliday'] ?? false,
      holidayReason: json['holidayReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'slots': slots.map((slot) => slot.toJson()).toList(),
      'isHoliday': isHoliday,
      'holidayReason': holidayReason,
    };
  }
}

class DefaultWorkingHours {
  final String day;
  final bool isWorking;
  final List<CalendarTimeSlot> slots;

  DefaultWorkingHours({
    required this.day,
    this.isWorking = true,
    required this.slots,
  });

  factory DefaultWorkingHours.fromJson(Map<String, dynamic> json) {
    List<dynamic> slotsList = json['slots'] ?? [];
    return DefaultWorkingHours(
      day: json['day'] ?? '',
      isWorking: json['isWorking'] ?? true,
      slots: slotsList.map((slot) => CalendarTimeSlot.fromJson(slot)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isWorking': isWorking,
      'slots': slots.map((slot) => slot.toJson()).toList(),
    };
  }
}

class DoctorCalendar {
  final String id;
  final String doctorId;
  final List<DaySchedule> schedule;
  final List<DefaultWorkingHours> defaultWorkingHours;
  final DateTime lastUpdated;

  DoctorCalendar({
    required this.id,
    required this.doctorId,
    required this.schedule,
    required this.defaultWorkingHours,
    required this.lastUpdated,
  });

  factory DoctorCalendar.fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> scheduleList = json['schedule'] ?? [];
      List<dynamic> defaultWorkingHoursList = json['defaultWorkingHours'] ?? [];

      String doctorId = '';
      // Handle both string and object doctor IDs
      if (json['doctorId'] != null) {
        if (json['doctorId'] is String) {
          doctorId = json['doctorId'];
        } else if (json['doctorId'] is Map) {
          doctorId = json['doctorId']['_id']?.toString() ?? '';
        }
      }

      return DoctorCalendar(
        id: json['_id']?.toString() ?? '',
        doctorId: doctorId,
        schedule: scheduleList
            .map((schedule) => DaySchedule.fromJson(schedule))
            .toList(),
        defaultWorkingHours: defaultWorkingHoursList
            .map((workingHours) => DefaultWorkingHours.fromJson(workingHours))
            .toList(),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'].toString())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing DoctorCalendar: $e');
      // Return a default empty calendar instead of throwing
      return DoctorCalendar(
        id: '',
        doctorId: '',
        schedule: [],
        defaultWorkingHours: [],
        lastUpdated: DateTime.now(),
      );
    }
  }
}

class AvailableSlots {
  final DateTime date;
  final bool isHoliday;
  final String? holidayReason;
  final List<CalendarTimeSlot> availableSlots;

  AvailableSlots({
    required this.date,
    this.isHoliday = false,
    this.holidayReason,
    required this.availableSlots,
  });

  factory AvailableSlots.fromJson(Map<String, dynamic> json) {
    List<dynamic> slotsList = json['availableSlots'] ?? [];
    return AvailableSlots(
      date: DateTime.parse(json['date']),
      isHoliday: json['isHoliday'] ?? false,
      holidayReason: json['holidayReason'],
      availableSlots:
          slotsList.map((slot) => CalendarTimeSlot.fromJson(slot)).toList(),
    );
  }
}
