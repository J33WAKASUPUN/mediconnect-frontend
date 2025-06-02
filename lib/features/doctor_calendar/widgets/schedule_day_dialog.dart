import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:provider/provider.dart';

class ScheduleDayDialog extends StatefulWidget {
  final DateTime date;
  final Function(List<CalendarTimeSlot>, bool, String?) onSave;

  const ScheduleDayDialog({
    super.key,
    required this.date,
    required this.onSave,
  });

  @override
  State<ScheduleDayDialog> createState() => _ScheduleDayDialogState();
}

class _ScheduleDayDialogState extends State<ScheduleDayDialog> {
  List<CalendarTimeSlot> _slots = [];
  bool _isHoliday = false;
  final TextEditingController _holidayReasonController = TextEditingController();
  bool _isLoading = true;

  // Controllers for adding new slots
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }
  
  @override
  void dispose() {
    _holidayReasonController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      final daySchedule = calendarProvider.getScheduleForDate(widget.date);
      
      if (daySchedule != null) {
        setState(() {
          _slots = List<CalendarTimeSlot>.from(daySchedule.slots);
          _isHoliday = daySchedule.isHoliday;
          
          if (daySchedule.holidayReason != null && daySchedule.holidayReason!.isNotEmpty) {
            _holidayReasonController.text = daySchedule.holidayReason!;
          }
        });
      } else {
        // Get default working hours for this day
        final dayOfWeek = _getDayName(widget.date.weekday);
        final defaultWorkingHours = calendarProvider.getDefaultWorkingHoursForDay(dayOfWeek);
        
        if (defaultWorkingHours != null) {
          setState(() {
            _slots = List<CalendarTimeSlot>.from(defaultWorkingHours.slots);
            _isHoliday = !defaultWorkingHours.isWorking;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading schedule: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _getDayName(int weekday) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday];
  }

  void _addTimeSlot() {
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();
    
    // Check if inputs are valid
    if (startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter both start and end times'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    // Validate time format (HH:MM)
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!timeRegex.hasMatch(startTime) || !timeRegex.hasMatch(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid time format. Use HH:MM (24-hour format)'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    // Check if start time is before end time
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    if (startHour > endHour || (startHour == endHour && startMinute >= endMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Start time must be before end time'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    // Check for overlapping slots
    for (final slot in _slots) {
      final existingStartParts = slot.startTime.split(':');
      final existingEndParts = slot.endTime.split(':');
      final existingStartHour = int.parse(existingStartParts[0]);
      final existingStartMinute = int.parse(existingStartParts[1]);
      final existingEndHour = int.parse(existingEndParts[0]);
      final existingEndMinute = int.parse(existingEndParts[1]);
      
      // Check if new slot overlaps with existing slot
      if ((startHour < existingEndHour || (startHour == existingEndHour && startMinute < existingEndMinute)) &&
          (endHour > existingStartHour || (endHour == existingStartHour && endMinute > existingStartMinute))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This time slot overlaps with an existing one'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }
    
    // Add the new slot
    setState(() {
      _slots.add(CalendarTimeSlot(
        startTime: startTime,
        endTime: endTime,
      ));
      
      // Sort slots by start time
      _slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      // Clear input fields
      _startTimeController.clear();
      _endTimeController.clear();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Time slot added successfully'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  void _removeSlot(int index) {
    setState(() {
      _slots.removeAt(index);
    });
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Time slot removed'),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${widget.date.day} ${_getMonthName(widget.date.month)} ${widget.date.year}";
    final dayName = _getDayName(widget.date.weekday);

    final dayColor = _getDayColor(dayName);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _isLoading
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              height: 200,
              width: 200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: dayColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: dayColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getDayIcon(dayName),
                            color: dayColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule for $dateStr',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: dayColor,
                                ),
                              ),
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: dayColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Holiday toggle
                          Container(
                            decoration: BoxDecoration(
                              color: _isHoliday ? Colors.red.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isHoliday ? Colors.red.shade200 : Colors.grey.shade200,
                              ),
                            ),
                            child: SwitchListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    color: _isHoliday ? Colors.red : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Mark as Holiday',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'No appointments will be available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              value: _isHoliday,
                              activeColor: Colors.red,
                              onChanged: (value) {
                                setState(() {
                                  _isHoliday = value;
                                });
                              },
                            ),
                          ),
                          
                          // Holiday reason (if marked as holiday)
                          if (_isHoliday) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _holidayReasonController,
                              decoration: InputDecoration(
                                labelText: 'Holiday Reason',
                                hintText: 'e.g., Public Holiday, Leave, etc.',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                prefixIcon: Icon(
                                  Icons.label_outline,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Time slots section (if not a holiday)
                            const SizedBox(height: 16),
                            
                            // Time slots header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Colors.blue.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Time Slots',
                                    style: TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_slots.length} slots',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // List of existing time slots
                            if (_slots.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.schedule_outlined,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No time slots added yet',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _slots.length,
                                itemBuilder: (context, index) {
                                  final slot = _slots[index];
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.access_time,
                                          color: Colors.green.shade700,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        '${slot.startTime} - ${slot.endTime}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () => _removeSlot(index),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 24),
                            
                            // Add new time slot section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Add New Time Slot',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Time input fields
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTimeInputField(
                                          controller: _startTimeController,
                                          label: 'Start Time',
                                          hint: '09:00',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTimeInputField(
                                          controller: _endTimeController,
                                          label: 'End Time',
                                          hint: '17:00',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Add button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _addTimeSlot,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Time Slot'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_isHoliday || _slots.isNotEmpty) {
                                    widget.onSave(
                                      _slots,
                                      _isHoliday,
                                      _isHoliday ? _holidayReasonController.text : null,
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Please add at least one time slot or mark as holiday'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Save Schedule'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
  
  String _getMonthName(int month) {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][month - 1];
  }
  
  Color _getDayColor(String day) {
    switch (day) {
      case 'Monday':
        return Colors.blue;
      case 'Tuesday':
        return Colors.green;
      case 'Wednesday':
        return Colors.orange;
      case 'Thursday':
        return Colors.purple;
      case 'Friday':
        return Colors.teal;
      case 'Saturday':
        return Colors.red;
      case 'Sunday':
        return Colors.pink;
      default:
        return AppColors.primary;
    }
  }

  IconData _getDayIcon(String day) {
    switch (day) {
      case 'Monday':
        return Icons.work;
      case 'Tuesday':
        return Icons.work;
      case 'Wednesday':
        return Icons.work;
      case 'Thursday':
        return Icons.work;
      case 'Friday':
        return Icons.work;
      case 'Saturday':
        return Icons.weekend;
      case 'Sunday':
        return Icons.weekend;
      default:
        return Icons.calendar_today;
    }
  }
}