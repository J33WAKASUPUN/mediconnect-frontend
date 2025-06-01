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
  State<AppointmentBookingSheet> createState() => _AppointmentBookingSheetState();
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

  // Colors matching your dashboard
  static const Color primaryColor = Color(0xFF4D4DFF); // Purple/blue
  static const Color backgroundColor = Color(0xFFF6F6F6);
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadDoctorCalendar();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    reasonController.dispose();
    reasonFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _loadDoctorCalendar() async {
    setState(() {
      _isLoadingCalendar = true;
    });
    
    try {
      final calendarProvider = context.read<CalendarProvider>();
      
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      
      await calendarProvider.fetchCalendar(
        doctorId: widget.doctor.id,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading doctor calendar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCalendar = false;
        });
      }
    }
  }
  
  Future<void> _getAvailableSlotsForDate(DateTime date) async {
    if (mounted) {
      setState(() {
        _isLoadingSlots = true;
        _availableSlots = [];
      });
    }
    
    try {
      final calendarProvider = context.read<CalendarProvider>();
      
      await calendarProvider.fetchAvailableSlots(
        doctorId: widget.doctor.id,
        date: date,
      );
      
      if (calendarProvider.availableSlots != null) {
        final slots = calendarProvider.availableSlots!.availableSlots
            .map((slot) => '${slot.startTime} - ${slot.endTime}')
            .toList();
        
        if (mounted) {
          setState(() {
            _availableSlots = slots;
          });
        }
      } else {
        _getAvailableSlotsFromProfile(date);
      }
    } catch (e) {
      print('Error getting available slots: $e');
      _getAvailableSlotsFromProfile(date);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }
  
  void _getAvailableSlotsFromProfile(DateTime date) {
    final dayOfWeek = _getDayOfWeekName(date.weekday);
    
    final daySlots = widget.doctor.doctorProfile?.availableTimeSlots
        .where((slot) => slot.day == dayOfWeek)
        .toList();
    
    if (daySlots != null && daySlots.isNotEmpty) {
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
  
  String _getDayOfWeekName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  bool _isHoliday(DateTime date, CalendarProvider provider) {
    if (provider.calendar == null) return false;
    
    return provider.calendar!.schedule.any(
      (day) => day.isHoliday && 
               day.date.year == date.year && 
               day.date.month == date.month && 
               day.date.day == date.day
    );
  }
  
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
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Appointment header - similar to your dashboard header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Doctor profile info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: widget.doctor.profilePicture != null
                        ? NetworkImage(widget.doctor.profilePicture!)
                        : null,
                      child: widget.doctor.profilePicture == null
                        ? Text(
                            widget.doctor.firstName[0] + widget.doctor.lastName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Appointment with',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Dr. ${widget.doctor.firstName} ${widget.doctor.lastName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.doctor.doctorProfile?.specialization != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.doctor.doctorProfile!.specialization!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.zero,
              children: [
                // Doctor's Schedule Calendar View
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Doctor\'s Schedule',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            // Toggle view button
                            TextButton.icon(
                              icon: Icon(
                                _showCalendarView 
                                    ? Icons.view_list 
                                    : Icons.calendar_view_month,
                                size: 16,
                                color: primaryColor,
                              ),
                              label: Text(
                                _showCalendarView 
                                    ? 'List View' 
                                    : 'Calendar View',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                backgroundColor: primaryColor.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
                      ),
                      
                      // Divider
                      const Divider(height: 1),
                      
                      // Calendar or List view
                      if (_isLoadingCalendar)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: primaryColor),
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
                              style: TextStyle(
                                fontStyle: FontStyle.italic, 
                                color: Colors.grey
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          
                // Appointment Booking Form
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.book_online,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
          
                      // Date Selection
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SELECT DATE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                // Custom date picker
                                final date = await _selectDate(context, calendarProvider);
                                if (date != null) {
                                  setState(() {
                                    selectedDate = date;
                                    selectedTimeSlot = null;
                                  });
                                  
                                  _getAvailableSlotsForDate(date);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      selectedDate != null
                                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                          : 'Choose a date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selectedDate != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          
                      // Time Slot Selection
                      if (selectedDate != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELECT TIME SLOT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              if (_isLoadingSlots)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: CircularProgressIndicator(color: primaryColor),
                                  ),
                                )
                              else if (_availableSlots.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.red.shade400),
                                      const SizedBox(width: 12),
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 12,
                                  children: _availableSlots.map((slotText) {
                                    final isSelected = selectedTimeSlot == slotText;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedTimeSlot = isSelected ? null : slotText;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12, 
                                          horizontal: 16
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryColor : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? primaryColor : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          slotText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
          
                      // Reason for Visit
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REASON FOR VISIT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: reasonController,
                              focusNode: reasonFocusNode,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Briefly describe your symptoms or reason for visit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Consultation Fee Card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.payments_outlined,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Consultation Fee',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Pay after confirmation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs. ${widget.doctor.doctorProfile?.consultationFees ?? 0}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Book Button - fixed at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _canBook() ? () => _handleBookAppointment(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Book Appointment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                color: Colors.grey,
                onPressed: () {}, // Previous month (not implemented)
              ),
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                color: Colors.grey,
                onPressed: () {}, // Next month (not implemented)
              ),
            ],
          ),
        ),
        
        // Weekday headers with styled layout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ))
                .toList(),
          ),
        ),
        
        // Calendar grid with modern styling
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
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
              Color textColor = isPastDate ? Colors.grey.shade400 : Colors.black87;
              FontWeight fontWeight = FontWeight.normal;
              
              if (isSelected) {
                bgColor = primaryColor;
                textColor = Colors.white;
                fontWeight = FontWeight.bold;
              } else if (isToday) {
                bgColor = Colors.blue.withOpacity(0.1);
                textColor = Colors.blue.shade700;
                fontWeight = FontWeight.bold;
              } else if (isHoliday) {
                bgColor = Colors.red.withOpacity(0.08);
                textColor = Colors.red.shade700;
              } else if (isSpecialDay) {
                bgColor = Colors.orange.withOpacity(0.08);
                textColor = Colors.orange.shade800;
              }
              
              return GestureDetector(
                onTap: isPastDate || isHoliday ? null : () {
                  final selectedDate = DateTime(now.year, now.month, day);
                  
                  if (!_isHoliday(selectedDate, calendarProvider)) {
                    setState(() {
                      this.selectedDate = selectedDate;
                      selectedTimeSlot = null;
                    });
                    
                    _getAvailableSlotsForDate(selectedDate);
                  } else {
                    _safeShowSnackBar(
                      context, 
                      'The doctor is not available on this date'
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: fontWeight,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Legend with colored indicators
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Today', Colors.blue.withOpacity(0.1), Colors.blue.shade700),
              _buildLegendItem('Selected', primaryColor, Colors.white),
              _buildLegendItem('Holiday', Colors.red.withOpacity(0.08), Colors.red.shade700),
              _buildLegendItem('Special', Colors.orange.withOpacity(0.08), Colors.orange.shade800),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDoctorScheduleList(DoctorCalendar calendar) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default Working Hours with modern card style
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Default Weekly Schedule',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Column(
                  children: calendar.defaultWorkingHours
                      .where((day) => day.isWorking)
                      .map((day) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 90,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    day.day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                      fontSize: 13,
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
                                          margin: const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Text(
                                            '${slot.startTime} - ${slot.endTime}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: const Text(
                                        'Not Available',
                                        style: TextStyle(color: Colors.red),
                                      ),
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

          // Upcoming holidays with modern alert styling
          if (calendar.schedule.any((day) => day.isHoliday && day.date.isAfter(DateTime.now()))) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.event_busy, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Holidays',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: calendar.schedule
                  .where((day) => 
                      day.isHoliday && 
                      day.date.isAfter(DateTime.now()) &&
                      day.date.isBefore(DateTime.now().add(const Duration(days: 30))))
                  .map((holiday) {
                    final dateStr = DateTimeHelper.formatDate(holiday.date);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.red, size: 16),
                          const SizedBox(width: 12),
                          Text(
                            dateStr,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (holiday.holidayReason != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '- ${holiday.holidayReason}',
                                style: TextStyle(color: Colors.red.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
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
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color bgColor, Color textColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
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
  
  Future<DateTime?> _selectDate(BuildContext context, CalendarProvider calendarProvider) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 1));
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 30));
    
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
      selectableDayPredicate: (day) {
        return !_isHoliday(day, calendarProvider);
      },
    );
    
    return date;
  }
  
  Future<void> _handleBookAppointment(BuildContext context) async {
    if (selectedDate == null ||
        selectedTimeSlot == null ||
        reasonController.text.trim().isEmpty) {
      _safeShowSnackBar(context, 'Please fill in all required fields');
      return;
    }

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

      setState(() {
        _isLoading = false;
      });

      if (result) {
        if (context.mounted) {
          Navigator.pop(context);
          _showAppointmentBookedDialog(context, appointmentProvider.latestAppointment);
        }
      } else {
        if (context.mounted) {
          _safeShowSnackBar(
              context,
              appointmentProvider.error ?? 'Failed to book appointment');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        _safeShowSnackBar(context, 'An error occurred: $e');
      }
    }
  }
  
  void _showAppointmentBookedDialog(BuildContext context, appointment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Appointment Booked!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Your appointment has been booked successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'What would you like to do next?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  
                  // View appointments button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/patient/appointments');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View My Appointments'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Pay now button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        
                        if (appointment != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                appointment: appointment,
                              ),
                            ),
                          ).then((_) {
                            Navigator.pushReplacementNamed(context, '/patient/appointments');
                          });
                        } else {
                          _safeShowSnackBar(context, 'Could not find appointment details. Please go to your appointments to make the payment.');
                          Navigator.pushNamed(context, '/patient/appointments');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _safeShowSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ));
    }
  }

  bool _canBook() {
    return selectedDate != null &&
        selectedTimeSlot != null &&
        reasonController.text.trim().isNotEmpty;
  }
}