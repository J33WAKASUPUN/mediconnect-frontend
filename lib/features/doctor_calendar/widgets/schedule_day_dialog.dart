import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:provider/provider.dart';
class ScheduleDayDialog extends StatefulWidget {
  final DateTime date;
  final Function(List<CalendarTimeSlot>, bool, String?) onSave;

  const ScheduleDayDialog({
    Key? key,
    required this.date,
    required this.onSave,
  }) : super(key: key);

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
        SnackBar(content: Text('Error loading schedule: $e')),
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
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;
    
    // Check if inputs are valid
    if (startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both start and end times')),
      );
      return;
    }
    
    // Validate time format (HH:MM)
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!timeRegex.hasMatch(startTime) || !timeRegex.hasMatch(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid time format. Use HH:MM (24-hour format)')),
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
        const SnackBar(content: Text('Start time must be before end time')),
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
          const SnackBar(content: Text('This time slot overlaps with an existing one')),
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
  }
  
  void _removeSlot(int index) {
    setState(() {
      _slots.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${widget.date.day}/${widget.date.month}/${widget.date.year}";
    final dayName = _getDayName(widget.date.weekday);
    
    return Dialog(
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dialog title
                    Text(
                      'Schedule for $dateStr ($dayName)',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Holiday toggle
                    SwitchListTile(
                      title: const Text(
                        'Mark as Holiday',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('No appointments will be available'),
                      value: _isHoliday,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _isHoliday = value;
                        });
                      },
                    ),
                    
                    // Holiday reason (if marked as holiday)
                    if (_isHoliday) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _holidayReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Holiday Reason',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Public Holiday, Leave, etc.',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Time slots section (if not a holiday)
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Time Slots',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text('${_slots.length} slots'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // List of existing time slots
                      if (_slots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: Text('No time slots added yet')),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _slots.length,
                          itemBuilder: (context, index) {
                            final slot = _slots[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.access_time),
                                title: Text('${slot.startTime} - ${slot.endTime}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeSlot(index),
                                ),
                              ),
                            );
                          },
                        ),

                      // Add new time slot section
                      const SizedBox(height: 16),
                      const Text(
                        'Add New Slot',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Time input fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                hintText: 'HH:MM',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.watch_later_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _endTimeController,
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                hintText: 'HH:MM',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.watch_later_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Add button
                      ElevatedButton(
                        onPressed: _addTimeSlot,
                        child: const Text('Add Time Slot'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
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
                                const SnackBar(
                                  content: Text('Please add at least one time slot or mark as holiday'),
                                ),
                              );
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}