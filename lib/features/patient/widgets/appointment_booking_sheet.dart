import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/features/payment/screens/payment_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/calendar_model.dart';
import '../../../core/utils/datetime_helper.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class AppointmentBookingSheet extends StatefulWidget {
  final User doctor;
  final ScrollController scrollController;

  const AppointmentBookingSheet({
    super.key,
    required this.doctor,
    required this.scrollController,
  });

  @override
  State<AppointmentBookingSheet> createState() =>
      _AppointmentBookingSheetState();
}

class _AppointmentBookingSheetState extends State<AppointmentBookingSheet> {
  DateTime? selectedDate;
  String? selectedTimeSlot;
  final reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingCalendar = false;
  final FocusNode reasonFocusNode = FocusNode();
  bool _isLoadingSlots = false;
  List<String> _availableSlots = [];
  bool _showCalendarView = true; // Start with calendar view enabled

  @override
  void initState() {
    super.initState();
    // Load calendar data when sheet opens
    _loadDoctorCalendar();
    
    // Delay focus-related operations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This ensures the widget is fully built before any focus operations
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    reasonController.dispose();
    reasonFocusNode.dispose();
    super.dispose();
  }
  
  // Load doctor's calendar data for availability
  Future<void> _loadDoctorCalendar() async {
    setState(() {
      _isLoadingCalendar = true;
    });
    
    try {
      final calendarProvider = context.read<CalendarProvider>();
      
      // Get current month's range
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      
      // Load calendar data for the doctor
      await calendarProvider.fetchCalendar(
        doctorId: widget.doctor.id,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading doctor calendar: $e');
      // Don't show error - we'll fall back to profile time slots
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCalendar = false;
        });
      }
    }
  }
  
  // Get available slots for selected date
  Future<void> _getAvailableSlotsForDate(DateTime date) async {
    if (mounted) {
      setState(() {
        _isLoadingSlots = true;
        _availableSlots = [];
      });
    }
    
    try {
      final calendarProvider = context.read<CalendarProvider>();
      
      // Try to get available slots from calendar first
      await calendarProvider.fetchAvailableSlots(
        doctorId: widget.doctor.id,
        date: date,
      );
      
      if (calendarProvider.availableSlots != null) {
        // Use calendar's available slots
        final slots = calendarProvider.availableSlots!.availableSlots
            .map((slot) => '${slot.startTime} - ${slot.endTime}')
            .toList();
        
        if (mounted) {
          setState(() {
            _availableSlots = slots;
          });
        }
      } else {
        // Fall back to profile slots if calendar data is not available
        _getAvailableSlotsFromProfile(date);
      }
    } catch (e) {
      print('Error getting available slots: $e');
      // Fall back to profile slots
      _getAvailableSlotsFromProfile(date);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }
  
  // Get available slots from doctor's profile
  void _getAvailableSlotsFromProfile(DateTime date) {
    // Get day of week
    final dayOfWeek = _getDayOfWeekName(date.weekday);
    
    // Find matching day in doctor's available time slots
    final daySlots = widget.doctor.doctorProfile?.availableTimeSlots
        .where((slot) => slot.day == dayOfWeek)
        .toList();
    
    if (daySlots != null && daySlots.isNotEmpty) {
      // Map time slots to strings
      final slots = daySlots.first.slots
          .map((slot) => '${slot.startTime} - ${slot.endTime}')
          .toList();
      
      if (mounted) {
        setState(() {
          _availableSlots = slots;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _availableSlots = [];
        });
      }
    }
  }
  
  // Helper to get day of week name
  String _getDayOfWeekName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  // Check if a date is a holiday in calendar
  bool _isHoliday(DateTime date, CalendarProvider provider) {
    if (provider.calendar == null) return false;
    
    return provider.calendar!.schedule.any(
      (day) => day.isHoliday && 
               day.date.year == date.year && 
               day.date.month == date.month && 
               day.date.day == date.day
    );
  }
  
  // Get holiday reason (if available)
  String? _getHolidayReason(DateTime date, CalendarProvider provider) {
    if (provider.calendar == null) return null;
    
    final holidaySchedule = provider.calendar!.schedule.firstWhere(
      (day) => day.isHoliday && 
               day.date.year == date.year && 
               day.date.month == date.month && 
               day.date.day == date.day,
      orElse: () => DaySchedule(date: date, slots: []),
    );
    
    return holidaySchedule.holidayReason;
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Book Appointment',
            style: AppStyles.heading2,
          ),
          const SizedBox(height: 16),
          
          // Doctor's Schedule Calendar View
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Doctor\'s Schedule',
                        style: AppStyles.heading1.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      // Toggle between calendar and list view
                      TextButton.icon(
                        icon: Icon(
                          _showCalendarView 
                              ? Icons.view_list 
                              : Icons.calendar_view_month,
                          size: 18,
                        ),
                        label: Text(
                          _showCalendarView 
                              ? 'List View' 
                              : 'Calendar View',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showCalendarView = !_showCalendarView;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoadingCalendar)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (calendarProvider.calendar != null)
                    _showCalendarView 
                        ? _buildCalendarGridView(calendarProvider) 
                        : _buildDoctorScheduleList(calendarProvider.calendar!)
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Doctor\'s schedule is not available',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Appointment Booking Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Your Appointment',
                    style: AppStyles.heading1,
                  ),
                  const SizedBox(height: 16),

                  // Date Selection
                  Text(
                    'Select Date',
                    style: AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                      title: Text(
                        selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : 'Choose a date',
                      ),
                      onTap: () async {
                        // Custom function to select date that checks for holidays
                        final date = await _selectDate(context, calendarProvider);
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                            selectedTimeSlot = null; // Reset time slot when date changes
                          });
                          
                          // Get available slots for the selected date
                          _getAvailableSlotsForDate(date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Slot Selection
                  if (selectedDate != null) ...[
                    Text(
                      'Select Time Slot',
                      style: AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_isLoadingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No available slots for ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: _availableSlots.map((slotText) {
                            final isSelected = selectedTimeSlot == slotText;
                            return Material(
                              color: isSelected ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedTimeSlot = isSelected ? null : slotText;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10, 
                                    horizontal: 14
                                  ),
                                  child: Text(
                                    slotText,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: isSelected ? FontWeight.bold : null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Reason for Visit
                  Text(
                    'Reason for Visit',
                    style: AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    focusNode: reasonFocusNode,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Briefly describe your symptoms or reason for visit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Consultation Fee
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Fee',
                              style: AppStyles.bodyText1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pay after confirmation',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rs. ${widget.doctor.doctorProfile?.consultationFees ?? 0}',
                          style: AppStyles.heading2.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Book Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _canBook() ? () => _handleBookAppointment(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16), // Bottom padding for safe area
        ],
      ),
    );
  }
  
  // Build calendar grid view
  Widget _buildCalendarGridView(CalendarProvider calendarProvider) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;
    
    // Get holidays and special days
    final holidays = <int>[];
    final specialDays = <int>[];
    
    if (calendarProvider.calendar != null) {
      for (var day in calendarProvider.calendar!.schedule) {
        if (day.date.month == now.month && day.date.year == now.year) {
          if (day.isHoliday) {
            holidays.add(day.date.day);
          } else if (day.slots.isNotEmpty) {
            specialDays.add(day.date.day);
          }
        }
      }
    }
    
    return Column(
      children: [
        // Calendar header - month name
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            '${_getMonthName(now.month)} ${now.year}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) {
            return SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: (firstWeekdayOfMonth - 1) + daysInMonth,
          itemBuilder: (context, index) {
            // Empty cells before the 1st of month
            if (index < (firstWeekdayOfMonth - 1)) {
              return const SizedBox.shrink();
            }
            
            // Day cells
            final day = index - (firstWeekdayOfMonth - 1) + 1;
            final isToday = day == now.day;
            final isHoliday = holidays.contains(day);
            final isSpecialDay = specialDays.contains(day);
            final isSelected = selectedDate != null && 
                selectedDate!.day == day && 
                selectedDate!.month == now.month && 
                selectedDate!.year == now.year;
            
            // Determine the date for this cell
            final cellDate = DateTime(now.year, now.month, day);
            final isPastDate = cellDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
            
            Color bgColor = Colors.transparent;
            Color textColor = isPastDate ? Colors.grey.shade400 : Colors.black;
            Color borderColor = Colors.grey.withOpacity(0.2);
            FontWeight fontWeight = FontWeight.normal;
            
            if (isSelected) {
              bgColor = AppColors.primary;
              textColor = Colors.white;
              borderColor = AppColors.primary;
              fontWeight = FontWeight.bold;
            } else if (isToday) {
              bgColor = Colors.blue.withOpacity(0.2);
              borderColor = Colors.blue;
              fontWeight = FontWeight.bold;
            } else if (isHoliday) {
              bgColor = Colors.red.withOpacity(0.1);
              borderColor = Colors.red.withOpacity(0.3);
            } else if (isSpecialDay) {
              bgColor = Colors.orange.withOpacity(0.1);
              borderColor = Colors.orange.withOpacity(0.3);
            }
            
            return GestureDetector(
              onTap: isPastDate || isHoliday ? null : () {
                final selectedDate = DateTime(now.year, now.month, day);
                
                if (!_isHoliday(selectedDate, calendarProvider)) {
                  setState(() {
                    this.selectedDate = selectedDate;
                    selectedTimeSlot = null; // Reset time slot
                  });
                  
                  _getAvailableSlotsForDate(selectedDate);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('The doctor is not available on this date.'),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 16,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: fontWeight,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Today', Colors.blue.withOpacity(0.2), Colors.blue),
              _buildLegendItem('Selected', AppColors.primary, AppColors.primary),
              _buildLegendItem('Holiday', Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.3)),
              _buildLegendItem('Special Hours', Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.3)),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build working hours list from calendar data
  Widget _buildDoctorScheduleList(DoctorCalendar calendar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default Working Hours
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Default Weekly Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              
              Column(
                children: calendar.defaultWorkingHours
                    .where((day) => day.isWorking) // Only show working days
                    .map((day) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  day.day,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: day.isWorking
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: day.slots.map((slot) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          '${slot.startTime} - ${slot.endTime}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : const Text(
                                    'Not Available',
                                    style: TextStyle(color: Colors.red),
                                  ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ),

        // Upcoming holidays
        if (calendar.schedule.any((day) => day.isHoliday && day.date.isAfter(DateTime.now()))) ...[
          const SizedBox(height: 16),
          const Text(
            'Upcoming Holidays',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: calendar.schedule
                .where((day) => 
                    day.isHoliday && 
                    day.date.isAfter(DateTime.now()) &&
                    day.date.isBefore(DateTime.now().add(const Duration(days: 30))))
                .map((holiday) {
                  final dateStr = DateTimeHelper.formatDate(holiday.date);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (holiday.holidayReason != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '- ${holiday.holidayReason}',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
            ),
          ),
        ],
      ],
    );
  }
  
  // Helper for legend items
  Widget _buildLegendItem(String label, Color bgColor, Color borderColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  // Helper for month name
  String _getMonthName(int month) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];
  }
  
  // Custom date picker that disables holidays
  Future<DateTime?> _selectDate(BuildContext context, CalendarProvider calendarProvider) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 1));
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 30));
    
    // Make sure initialDate is not a holiday
    while (_isHoliday(initialDate, calendarProvider)) {
      initialDate = initialDate.add(const Duration(days: 1));
      if (initialDate.isAfter(lastDate)) {
        initialDate = lastDate;
        break;
      }
    }
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      
      // Disable holidays
      selectableDayPredicate: (day) {
        // Check if day is a holiday
        final isHol = _isHoliday(day, calendarProvider);
        
        if (isHol) {
          // Get the reason for holiday (if available)
          final reason = _getHolidayReason(day, calendarProvider);
          print('Day ${day.day}/${day.month} is a holiday${reason != null ? ": $reason" : ""}');
        }
        
        return !isHol;
      },
    );
    
    return date;
  }
  
  // Handler method for booking appointment
  Future<void> _handleBookAppointment(BuildContext context) async {
    // Validate inputs
    if (selectedDate == null ||
        selectedTimeSlot == null ||
        reasonController.text.trim().isEmpty) {
      _safeShowSnackBar(context, 'Please fill in all required fields');
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      final appointmentProvider = context.read<AppointmentProvider>();

      final result = await appointmentProvider.bookAppointment(
        doctorId: widget.doctor.id,
        appointmentDate: selectedDate!,
        timeSlot: selectedTimeSlot!,
        reason: reasonController.text.trim(),
        amount: widget.doctor.doctorProfile?.consultationFees ?? 0,
      );

      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      if (result) {
        // Close the bottom sheet
        if (context.mounted) {
          Navigator.pop(context);
          
          // Show options dialog
          _showAppointmentBookedDialog(context, appointmentProvider.latestAppointment);
        }
      } else {
        // Error
        if (context.mounted) {
          _safeShowSnackBar(
              context,
              appointmentProvider.error ?? 'Failed to book appointment');
        }
      }
    } catch (e) {
      // Handle any unexpected errors
      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        _safeShowSnackBar(context, 'An error occurred: $e');
      }
    }
  }
  
  // Show options dialog after booking
  void _showAppointmentBookedDialog(BuildContext context, appointment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Text('Appointment Booked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your appointment has been booked successfully.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do next?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamed(context, '/patient/appointments');
            },
            child: const Text('View My Appointments'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // If we have the appointment, navigate to payment
              if (appointment != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      appointment: appointment,
                    ),
                  ),
                ).then((_) {
                  // After payment flow completes, go to appointments
                  Navigator.pushReplacementNamed(context, '/patient/appointments');
                });
              } else {
                // Fallback if appointment isn't available
                _safeShowSnackBar(context, 'Could not find appointment details. Please go to your appointments to make the payment.');
                Navigator.pushNamed(context, '/patient/appointments');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  // Safe show SnackBar method
  void _safeShowSnackBar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ));
      }
    });
  }

  // Check if booking is possible
  bool _canBook() {
    return selectedDate != null &&
        selectedTimeSlot != null &&
        reasonController.text.trim().isNotEmpty;
  }
}