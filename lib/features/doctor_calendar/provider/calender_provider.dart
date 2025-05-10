import 'package:flutter/foundation.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/core/services/api_service.dart';

class CalendarProvider with ChangeNotifier {
  final ApiService _apiService;

  DoctorCalendar? _calendar;
  AvailableSlots? _availableSlots;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  CalendarProvider({required ApiService apiService}) : _apiService = apiService;

  DoctorCalendar? get calendar => _calendar;
  AvailableSlots? get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Get doctor's calendar for a date range
  Future<DoctorCalendar?> fetchCalendar({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  }) async {
    // Skip if already loading or if already initialized and not forcing refresh
    if (_isLoading) return _calendar;

    // Skip loading if we already have calendar data and not forcing refresh
    if (_calendar != null && !forceRefresh) return _calendar;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(
          'Fetching calendar for doctorId: $doctorId, date range: $startDate to $endDate');
      _calendar = await _apiService.getCalendar(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      _isInitialized = true; // Mark as initialized

      print(
          'Calendar fetched successfully: ${_calendar != null}, doctorId: $doctorId');
      notifyListeners();
      return _calendar;
    } catch (e) {
      print('Error fetching calendar: $e');
      _isLoading = false;
      _error = e.toString();

      if (_calendar == null) {
        _calendar = DoctorCalendar(
          id: 'default',
          doctorId: doctorId,
          schedule: [],
          defaultWorkingHours: _getDefaultWorkingHours(),
          lastUpdated: DateTime.now(),
        );
        _isInitialized = true; // Mark as initialized even with default data
      }

      notifyListeners();
      return _calendar;
    }
  }

  // Force refresh calendar data - useful for UI buttons
  void forceCalendarRefresh() {
    if (_calendar != null) {
      print('Forcing calendar refresh notification');
      notifyListeners();
    }
  }

  // Reset the provider state - useful when changing contexts
  void resetState() {
    _calendar = null;
    _availableSlots = null;
    _isLoading = false;
    _error = null;
    _isInitialized = false;
    notifyListeners();
    print('Calendar provider state reset');
  }

  // Helper method to create default working hours
  List<DefaultWorkingHours> _getDefaultWorkingHours() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days.map((day) {
      return DefaultWorkingHours(
        day: day,
        isWorking: day != 'Sunday',
        slots: day != 'Sunday'
            ? [
                CalendarTimeSlot(
                  startTime: '09:00',
                  endTime: '12:00',
                ),
                CalendarTimeSlot(
                  startTime: '13:00',
                  endTime: '17:00',
                ),
              ]
            : [],
      );
    }).toList();
  }

  // Set default working hours for the week
  Future<void> setDefaultWorkingHours(
      List<DefaultWorkingHours> defaultWorkingHours) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _calendar = await _apiService.setDefaultWorkingHours(defaultWorkingHours);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error setting default working hours: $e');
      _isLoading = false;
      _error = e.toString();

      // Update the working hours locally even if the server call failed
      if (_calendar != null) {
        _calendar = DoctorCalendar(
          id: _calendar!.id,
          doctorId: _calendar!.doctorId,
          schedule: _calendar!.schedule,
          defaultWorkingHours: defaultWorkingHours,
          lastUpdated: DateTime.now(),
        );
      }

      notifyListeners();
      // Don't rethrow, just log the error
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
      final updatedCalendar = await _apiService.updateDateSchedule(
        date: date,
        slots: slots,
        isHoliday: isHoliday,
        holidayReason: holidayReason,
      );

      // Update the local calendar with the updated schedule
      if (_calendar != null) {
        final existingScheduleIndex = _calendar!.schedule.indexWhere((s) =>
            DateTime(s.date.year, s.date.month, s.date.day)
                .isAtSameMomentAs(DateTime(date.year, date.month, date.day)));

        final newSchedule = List<DaySchedule>.from(_calendar!.schedule);

        // Add or replace the day schedule
        final updatedSchedule = updatedCalendar.schedule.isNotEmpty
            ? updatedCalendar.schedule.first
            : DaySchedule(
                date: date,
                slots: slots,
                isHoliday: isHoliday,
                holidayReason: holidayReason,
              );

        if (existingScheduleIndex != -1) {
          newSchedule[existingScheduleIndex] = updatedSchedule;
        } else {
          newSchedule.add(updatedSchedule);
        }

        _calendar = DoctorCalendar(
          id: _calendar!.id,
          doctorId: _calendar!.doctorId,
          schedule: newSchedule,
          defaultWorkingHours: _calendar!.defaultWorkingHours,
          lastUpdated: DateTime.now(),
        );
      } else {
        _calendar = updatedCalendar;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error updating date schedule: $e');
      _isLoading = false;
      _error = e.toString();

      // Update the schedule locally even if server call failed
      if (_calendar != null) {
        final existingScheduleIndex = _calendar!.schedule.indexWhere((s) =>
            DateTime(s.date.year, s.date.month, s.date.day)
                .isAtSameMomentAs(DateTime(date.year, date.month, date.day)));

        final newSchedule = List<DaySchedule>.from(_calendar!.schedule);

        final updatedSchedule = DaySchedule(
          date: date,
          slots: slots,
          isHoliday: isHoliday,
          holidayReason: holidayReason,
        );

        if (existingScheduleIndex != -1) {
          newSchedule[existingScheduleIndex] = updatedSchedule;
        } else {
          newSchedule.add(updatedSchedule);
        }

        _calendar = DoctorCalendar(
          id: _calendar!.id,
          doctorId: _calendar!.doctorId,
          schedule: newSchedule,
          defaultWorkingHours: _calendar!.defaultWorkingHours,
          lastUpdated: DateTime.now(),
        );
      }

      notifyListeners();
      // Don't rethrow, just log the error
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
      final updatedCalendar = await _apiService.blockTimeSlot(
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );

      // Update the local calendar with the blocked slot
      if (_calendar != null && updatedCalendar.schedule.isNotEmpty) {
        final existingScheduleIndex = _calendar!.schedule.indexWhere((s) =>
            DateTime(s.date.year, s.date.month, s.date.day)
                .isAtSameMomentAs(DateTime(date.year, date.month, date.day)));

        final newSchedule = List<DaySchedule>.from(_calendar!.schedule);

        if (existingScheduleIndex != -1) {
          newSchedule[existingScheduleIndex] = updatedCalendar.schedule.first;
        } else {
          newSchedule.add(updatedCalendar.schedule.first);
        }

        _calendar = DoctorCalendar(
          id: _calendar!.id,
          doctorId: _calendar!.doctorId,
          schedule: newSchedule,
          defaultWorkingHours: _calendar!.defaultWorkingHours,
          lastUpdated: DateTime.now(),
        );
      } else {
        _calendar = updatedCalendar;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error blocking time slot: $e');
      _isLoading = false;
      _error = e.toString();

      // Add the blocked slot locally even if server call failed
      if (_calendar != null) {
        final newSlot = CalendarTimeSlot(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          startTime: startTime,
          endTime: endTime,
          isBlocked: true,
        );

        final existingScheduleIndex = _calendar!.schedule.indexWhere((s) =>
            DateTime(s.date.year, s.date.month, s.date.day)
                .isAtSameMomentAs(DateTime(date.year, date.month, date.day)));

        final newSchedule = List<DaySchedule>.from(_calendar!.schedule);

        if (existingScheduleIndex != -1) {
          final existingSlots = List<CalendarTimeSlot>.from(
              newSchedule[existingScheduleIndex].slots);
          existingSlots.add(newSlot);

          newSchedule[existingScheduleIndex] = DaySchedule(
            id: newSchedule[existingScheduleIndex].id,
            date: newSchedule[existingScheduleIndex].date,
            slots: existingSlots,
            isHoliday: newSchedule[existingScheduleIndex].isHoliday,
            holidayReason: newSchedule[existingScheduleIndex].holidayReason,
          );
        } else {
          newSchedule.add(DaySchedule(
            date: date,
            slots: [newSlot],
            isHoliday: false,
          ));
        }

        _calendar = DoctorCalendar(
          id: _calendar!.id,
          doctorId: _calendar!.doctorId,
          schedule: newSchedule,
          defaultWorkingHours: _calendar!.defaultWorkingHours,
          lastUpdated: DateTime.now(),
        );
      }

      notifyListeners();
      // Don't rethrow, just log the error
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
      print('Error fetching available slots: $e');
      _isLoading = false;
      _error = e.toString();

      // Create empty available slots if there was an error
      _availableSlots = AvailableSlots(
        date: date,
        isHoliday: false,
        availableSlots: [],
      );

      notifyListeners();
      // Don't rethrow, just log the error
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
      final updatedCalendar = await _apiService.unblockTimeSlot(
        date: date,
        slotId: slotId,
      );

      // Update the local calendar with the unblocked slot
      if (_calendar != null) {
        final existingScheduleIndex = _calendar!.schedule.indexWhere((s) =>
            DateTime(s.date.year, s.date.month, s.date.day)
                .isAtSameMomentAs(DateTime(date.year, date.month, date.day)));

        final newSchedule = List<DaySchedule>.from(_calendar!.schedule);

        if (existingScheduleIndex != -1) {
          final existingSlots = List<CalendarTimeSlot>.from(
              newSchedule[existingScheduleIndex].slots);
          existingSlots.removeWhere((slot) => slot.id == slotId);

          newSchedule[existingScheduleIndex] = DaySchedule(
            id: newSchedule[existingScheduleIndex].id,
            date: newSchedule[existingScheduleIndex].date,
            slots: existingSlots,
            isHoliday: newSchedule[existingScheduleIndex].isHoliday,
            holidayReason: newSchedule[existingScheduleIndex].holidayReason,
          );
        }

        _calendar = DoctorCalendar(
          id: _calendar!.id,
          doctorId: _calendar!.doctorId,
          schedule: newSchedule,
          defaultWorkingHours: _calendar!.defaultWorkingHours,
          lastUpdated: DateTime.now(),
        );
      } else {
        _calendar = updatedCalendar;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error unblocking time slot: $e');
      _isLoading = false;
      _error = e.toString();

      // Remove the blocked slot locally even if server call failed
      if (_calendar != null) {
        final existingScheduleIndex = _calendar!.schedule.indexWhere((s) =>
            DateTime(s.date.year, s.date.month, s.date.day)
                .isAtSameMomentAs(DateTime(date.year, date.month, date.day)));

        if (existingScheduleIndex != -1) {
          final newSchedule = List<DaySchedule>.from(_calendar!.schedule);
          final existingSlots = List<CalendarTimeSlot>.from(
              newSchedule[existingScheduleIndex].slots);

          existingSlots.removeWhere((slot) => slot.id == slotId);

          newSchedule[existingScheduleIndex] = DaySchedule(
            id: newSchedule[existingScheduleIndex].id,
            date: newSchedule[existingScheduleIndex].date,
            slots: existingSlots,
            isHoliday: newSchedule[existingScheduleIndex].isHoliday,
            holidayReason: newSchedule[existingScheduleIndex].holidayReason,
          );

          _calendar = DoctorCalendar(
            id: _calendar!.id,
            doctorId: _calendar!.doctorId,
            schedule: newSchedule,
            defaultWorkingHours: _calendar!.defaultWorkingHours,
            lastUpdated: DateTime.now(),
          );
        }
      }

      notifyListeners();
      // Don't rethrow, just log the error
    }
  }

  // Get schedule for a specific date
  DaySchedule? getScheduleForDate(DateTime date) {
    if (_calendar == null) {
      // Return default empty schedule for that date
      return DaySchedule(
        date: date,
        slots: [],
        isHoliday: false,
      );
    }

    final targetDate = DateTime(date.year, date.month, date.day);

    try {
      return _calendar!.schedule.firstWhere(
        (schedule) =>
            DateTime(schedule.date.year, schedule.date.month, schedule.date.day)
                .isAtSameMomentAs(targetDate),
        orElse: () => DaySchedule(
          date: targetDate,
          slots: [],
        ),
      );
    } catch (e) {
      // Safety in case of any error
      print('Error in getScheduleForDate: $e');
      return DaySchedule(
        date: targetDate,
        slots: [],
      );
    }
  }

  // Get default working hours for a specific day of week
  DefaultWorkingHours? getDefaultWorkingHoursForDay(String day) {
    if (_calendar == null || _calendar!.defaultWorkingHours.isEmpty) {
      // Return default working hours for that day
      final isWeekend = day == 'Saturday' || day == 'Sunday';
      return DefaultWorkingHours(
        day: day,
        isWorking: !isWeekend,
        slots: !isWeekend
            ? [
                CalendarTimeSlot(
                  startTime: '09:00',
                  endTime: '12:00',
                ),
                CalendarTimeSlot(
                  startTime: '13:00',
                  endTime: '17:00',
                ),
              ]
            : [],
      );
    }

    try {
      return _calendar!.defaultWorkingHours.firstWhere(
        (workingHours) => workingHours.day == day,
        orElse: () => DefaultWorkingHours(
          day: day,
          slots: [],
        ),
      );
    } catch (e) {
      // Safety in case of any error
      print('Error in getDefaultWorkingHoursForDay: $e');
      return DefaultWorkingHours(
        day: day,
        slots: [],
      );
    }
  }
}
