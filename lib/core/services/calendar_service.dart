import 'package:mediconnect/config/api_endpoints.dart';
import 'package:mediconnect/core/models/calendar_model.dart';

import 'base_api_service.dart';

class CalendarService extends BaseApiService {
  String? _authToken;

  // Set auth token
  @override
  void setAuthToken(String token) {
    _authToken = token;
    super.setAuthToken(token);
  }

  // Get doctor's calendar for a date range
  Future<DoctorCalendar> getCalendar({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await get(
        '${ApiEndpoints.calendar}/$doctorId',
        queryParams: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      
      if (response['success'] == true && response['data'] != null) {
        return DoctorCalendar.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to load calendar');
      }
    } catch (e) {
      throw Exception('Failed to load calendar: $e');
    }
  }
  
  // Set default working hours for the week
  Future<DoctorCalendar> setDefaultWorkingHours(List<DefaultWorkingHours> defaultWorkingHours) async {
    try {
      final response = await post(
        ApiEndpoints.calendarWorkingHours,
        data: {
          'defaultWorkingHours': defaultWorkingHours.map((wh) => wh.toJson()).toList(),
        },
      );
      
      if (response['success'] == true && response['data'] != null) {
        return DoctorCalendar.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to set default working hours');
      }
    } catch (e) {
      throw Exception('Failed to set default working hours: $e');
    }
  }
  
  // Update specific date schedule
  Future<DoctorCalendar> updateDateSchedule({
    required DateTime date,
    required List<CalendarTimeSlot> slots,
    bool isHoliday = false,
    String? holidayReason,
  }) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];
      final response = await put(
        '${ApiEndpoints.calendarDate}/$formattedDate',
        data: {
          'slots': slots.map((slot) => slot.toJson()).toList(),
          'isHoliday': isHoliday,
          'holidayReason': holidayReason,
        },
      );
      
      if (response['success'] == true && response['data'] != null) {
        return DoctorCalendar.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update date schedule');
      }
    } catch (e) {
      throw Exception('Failed to update date schedule: $e');
    }
  }
  
  // Block time slot
  Future<DoctorCalendar> blockTimeSlot({
    required DateTime date,
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    try {
      final response = await post(
        ApiEndpoints.calendarBlockSlot,
        data: {
          'date': date.toIso8601String(),
          'startTime': startTime,
          'endTime': endTime,
          'reason': reason,
        },
      );
      
      if (response['success'] == true && response['data'] != null) {
        return DoctorCalendar.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to block time slot');
      }
    } catch (e) {
      throw Exception('Failed to block time slot: $e');
    }
  }
  
  // Get available slots for a specific date
  Future<AvailableSlots> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await get(
        '${ApiEndpoints.calendarAvailableSlots}/$doctorId/$dateString',
      );
      
      if (response['success'] == true && response['data'] != null) {
        return AvailableSlots.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get available slots');
      }
    } catch (e) {
      throw Exception('Failed to get available slots: $e');
    }
  }
  
  // Unblock time slot
  Future<DoctorCalendar> unblockTimeSlot({
    required DateTime date,
    required String slotId,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await delete(
        '${ApiEndpoints.calendarBlockSlot}/$dateString/$slotId',
      );
      
      if (response['success'] == true && response['data'] != null) {
        return DoctorCalendar.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to unblock time slot');
      }
    } catch (e) {
      throw Exception('Failed to unblock time slot: $e');
    }
  }
}