import 'package:flutter/foundation.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/core/services/api_service.dart';

class CalendarProvider with ChangeNotifier {
  final ApiService _apiService;
  
  DoctorCalendar? _calendar;
  AvailableSlots? _availableSlots;
  bool _isLoading = false;
  String? _error;
  
  CalendarProvider({required ApiService apiService}) : _apiService = apiService;
  
  DoctorCalendar? get calendar => _calendar;
  AvailableSlots? get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get doctor's calendar for a date range
  Future<void> fetchCalendar({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _calendar = await _apiService.getCalendar(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Set default working hours for the week
  Future<void> setDefaultWorkingHours(List<DefaultWorkingHours> defaultWorkingHours) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _calendar = await _apiService.setDefaultWorkingHours(defaultWorkingHours);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Update specific date schedule
  Future<void> updateDateSchedule({
    required DateTime date,
    required List<CalendarTimeSlot> slots,
    bool isHoliday = false,
    String? holidayReason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _calendar = await _apiService.updateDateSchedule(
        date: date,
        slots: slots,
        isHoliday: isHoliday,
        holidayReason: holidayReason,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Block time slot
  Future<void> blockTimeSlot({
    required DateTime date,
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _calendar = await _apiService.blockTimeSlot(
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Get available slots for a specific date
  Future<void> fetchAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _availableSlots = await _apiService.getAvailableSlots(
        doctorId: doctorId,
        date: date,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Unblock time slot
  Future<void> unblockTimeSlot({
    required DateTime date,
    required String slotId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _calendar = await _apiService.unblockTimeSlot(
        date: date,
        slotId: slotId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Get schedule for a specific date
  DaySchedule? getScheduleForDate(DateTime date) {
    if (_calendar == null) return null;
    
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return _calendar!.schedule.firstWhere(
      (schedule) => DateTime(
        schedule.date.year, 
        schedule.date.month, 
        schedule.date.day
      ).isAtSameMomentAs(targetDate),
      orElse: () => DaySchedule(
        date: targetDate,
        slots: [],
      ),
    );
  }
  
  // Get default working hours for a specific day of week
  DefaultWorkingHours? getDefaultWorkingHoursForDay(String day) {
    if (_calendar == null) return null;
    
    return _calendar!.defaultWorkingHours.firstWhere(
      (workingHours) => workingHours.day == day,
      orElse: () => DefaultWorkingHours(
        day: day,
        slots: [],
      ),
    );
  }
}