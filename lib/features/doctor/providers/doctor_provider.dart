import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class DoctorProvider with ChangeNotifier {
  final ApiService _apiService;
  User? _doctorProfile;
  bool _isLoading = false;
  String? _error;
  String _lastUpdated = '2025-05-13 03:15:38'; // Current UTC timestamp

  // Metrics for the dashboard
  int _patientCount = 0;
  int _newPatientsThisMonth = 0;
  int _totalConsultations = 0;
  int _pendingAppointments = 0;
  List<dynamic> _todayActiveAppointments = [];

  // Calendar metrics
  int _totalDaysInMonth = 0;
  int _workDaysInMonth = 0;
  int _holidaysInMonth = 0;
  int _weekendDaysInMonth = 0;

  // Calculate work days in the current month (simpler calculation)
  int calculateWorkDaysSoFar(CalendarProvider? calendarProvider) {
    try {
      // Get current date details
      final now = DateTime.now();
      final currentDay = now.day; // Today's day of month

      print("Current date: ${now.year}-${now.month}-${now.day}");
      print("Days elapsed so far this month: $currentDay");

      // Get holidays from calendar if available
      Set<int> holidayDays = {};
      if (calendarProvider?.calendar != null) {
        // Extract holiday days from calendar
        for (var daySchedule in calendarProvider!.calendar!.schedule) {
          if (daySchedule.date.year == now.year &&
              daySchedule.date.month == now.month &&
              daySchedule.date.day <=
                  currentDay && // Only include holidays up to today
              daySchedule.isHoliday) {
            holidayDays.add(daySchedule.date.day);
          }
        }
      }

      print("Holidays so far this month: ${holidayDays.length}");

      // Count only up to today (including today)
      int workDaysSoFar = 0;
      for (int day = 1; day <= currentDay; day++) {
        final date = DateTime(now.year, now.month, day);
        // Count as work day if it's not a weekend AND not a holiday
        if (date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday &&
            !holidayDays.contains(day)) {
          workDaysSoFar++;
        }
      }

      print("Counted work days so far (excluding holidays): $workDaysSoFar");
      return workDaysSoFar;
    } catch (e) {
      print("Error calculating work days so far: $e");
      return 9; // Default to 9 days as suggested
    }
  }

  DoctorProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  User? get doctorProfile => _doctorProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastUpdated => _lastUpdated;
  int get patientCount => _patientCount;
  int get newPatientsThisMonth => _newPatientsThisMonth;
  int get totalConsultations => _totalConsultations;
  int get pendingAppointments => _pendingAppointments;
  List<dynamic> get todayActiveAppointments => _todayActiveAppointments;

  // Calendar metrics getters
  int get totalDaysInMonth => _totalDaysInMonth;
  int get workDaysInMonth => _workDaysInMonth;
  int get holidaysInMonth => _holidaysInMonth;
  int get weekendDaysInMonth => _weekendDaysInMonth;

  // Get doctor profile
  Future<void> getDoctorProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getProfile();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        if (data['doctorProfile'] != null) {
          _doctorProfile =
              DoctorProfile.fromJson(data['doctorProfile']) as User?;

          // Debug information
          print("Doctor profile loaded: $_doctorProfile");
          print("Specialization: ${_doctorProfile?.specialization}");
          print("Experience: ${_doctorProfile?.yearsOfExperience}");
        } else {
          _doctorProfile = DoctorProfile() as User?; // Default empty profile
        }
      }

      // Update timestamp
      _lastUpdated = DateTime.now().toUtc().toString();
    } catch (e) {
      _error = e.toString();
      print("Error getting doctor profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate metrics based on appointment data
  void calculateMetrics(AppointmentProvider appointmentProvider) {
    try {
      // Get unique patients from all appointments
      final Set<String> uniquePatientIds = {};
      final Set<String> thisMonthPatientIds = {};
      final now = DateTime.now();
      int completedConsultations = 0;

      // Extract today's active appointments first
      final today = DateTime.now();
      _todayActiveAppointments = appointmentProvider.appointments.where((apt) {
        return apt.appointmentDate.year == today.year &&
            apt.appointmentDate.month == today.month &&
            apt.appointmentDate.day == today.day &&
            apt.status != 'completed' &&
            apt.status != 'cancelled';
      }).toList();

      // Process all appointments for metrics
      for (var appointment in appointmentProvider.appointments) {
        // Skip appointments without valid patient ID
        if (appointment.patientId.isEmpty) continue;

        // Count unique patients
        uniquePatientIds.add(appointment.patientId);

        // Track patients from this month
        if (appointment.createdAt.month == now.month &&
            appointment.createdAt.year == now.year) {
          thisMonthPatientIds.add(appointment.patientId);
        }

        // Count completed appointments
        if (appointment.status == 'completed') {
          completedConsultations++;
        }
      }

      // Update metrics
      _patientCount = uniquePatientIds.length;
      _newPatientsThisMonth = thisMonthPatientIds.length;
      _totalConsultations = completedConsultations;
      _pendingAppointments = appointmentProvider.appointments
          .where((apt) => apt.status == 'pending')
          .length;

      print("Appointment metrics updated");
      notifyListeners();
    } catch (e) {
      print("Error calculating metrics: $e");
      // If calculation fails, keep the current values
    }
  }

  // Calculate calendar metrics based on calendar data
  void calculateCalendarMetrics(CalendarProvider calendarProvider) {
    try {
      if (calendarProvider.calendar == null) {
        _calculateDefaultCalendarMetrics();
        return;
      }

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;

      // Initialize counters
      _totalDaysInMonth = daysInMonth;
      _holidaysInMonth = 0;
      int weekendDays = 0;

      // Get holidays from calendar schedule
      final calendarSchedule = calendarProvider.calendar!.schedule;
      for (var day in calendarSchedule) {
        // Only count days in current month
        if (day.date.year == now.year && day.date.month == now.month) {
          if (day.isHoliday) {
            _holidaysInMonth++;
          }
        }
      }

      // Count weekend days
      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          weekendDays++;
        }
      }

      _weekendDaysInMonth = weekendDays;

      // Working days = total days - weekends - holidays
      _workDaysInMonth = daysInMonth - weekendDays - _holidaysInMonth;

      print(
          "Calendar metrics updated: $_workDaysInMonth working days, $_holidaysInMonth holidays, $_weekendDaysInMonth weekend days");
      notifyListeners();
    } catch (e) {
      print("Error calculating calendar metrics: $e");
      _calculateDefaultCalendarMetrics();
    }
  }

  // Calculate default calendar metrics when no calendar data is available
  void _calculateDefaultCalendarMetrics() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    _totalDaysInMonth = daysInMonth;
    _holidaysInMonth = 0;

    // Count weekend days (Saturday and Sunday)
    int weekendDays = 0;
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        weekendDays++;
      }
    }

    _weekendDaysInMonth = weekendDays;
    _workDaysInMonth = daysInMonth - weekendDays;

    print(
        "Default calendar metrics calculated: $_workDaysInMonth working days, $_weekendDaysInMonth weekend days");
    notifyListeners();
  }
}
