import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../core/models/profile_models.dart';

class AvailabilityEditor extends StatefulWidget {
  final List<AvailableTimeSlot> initialAvailability;
  final Function(List<AvailableTimeSlot>) onSave;

  const AvailabilityEditor({
    super.key,
    required this.initialAvailability,
    required this.onSave,
  });

  @override
  _AvailabilityEditorState createState() => _AvailabilityEditorState();
}

class _AvailabilityEditorState extends State<AvailabilityEditor> {
  late List<AvailableTimeSlot> _availability;
  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    
    // Create copy of initial data
    _availability = List.from(widget.initialAvailability);
    
    // Make sure all weekdays exist
    for (final day in _weekdays) {
      if (!_availability.any((slot) => slot.day == day)) {
        _availability.add(AvailableTimeSlot(day: day));
      }
    }
    
    // Sort days in proper order
    _availability.sort((a, b) => 
        _weekdays.indexOf(a.day).compareTo(_weekdays.indexOf(b.day)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Availability', style: AppStyles.heading2),
        const SizedBox(height: 16),
        
        Text(
          'Set your available time slots for each day of the week.',
          style: AppStyles.bodyText1,
        ),
        const SizedBox(height: 16),
        
        // Days list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availability.length,
          itemBuilder: (context, index) {
            final daySlot = _availability[index];
            return _buildDayItem(daySlot);
          }
        ),
        
        const SizedBox(height: 24),
        
        // Save button
        Center(
          child: ElevatedButton(
            onPressed: () {
              widget.onSave(_availability);
            },
            child: const Text('Save Availability'),
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem(AvailableTimeSlot daySlot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  daySlot.day,
                  style: AppStyles.heading1,
                ),
                TextButton.icon(
                  onPressed: () => _addTimeSlot(daySlot),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time Slot'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (daySlot.slots.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No available slots'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: daySlot.slots.map((timeSlot) {
                  return InputChip(
                    label: Text('${timeSlot.startTime} - ${timeSlot.endTime}'),
                    onDeleted: () => _removeTimeSlot(daySlot, timeSlot),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppColors.primary),
                    deleteIconColor: AppColors.primary,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTimeSlot(AvailableTimeSlot daySlot) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (startTime == null) return;
    
    // Default duration: 30 minutes
    final endHour = (startTime.hour + ((startTime.minute + 30) ~/ 60)) % 24;
    final endMinute = (startTime.minute + 30) % 60;
    
    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: endHour, minute: endMinute),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (endTime == null) return;
    
    setState(() {
      final index = _availability.indexOf(daySlot);
      final newSlots = List<TimeSlot>.from(daySlot.slots);
      
      newSlots.add(TimeSlot(
        startTime: _formatTimeOfDay(startTime),
        endTime: _formatTimeOfDay(endTime),
      ));
      
      // Sort by start time
      newSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      _availability[index] = AvailableTimeSlot(
        day: daySlot.day,
        slots: newSlots,
      );
    });
  }

  void _removeTimeSlot(AvailableTimeSlot daySlot, TimeSlot timeSlot) {
    setState(() {
      final index = _availability.indexOf(daySlot);
      final newSlots = daySlot.slots.where((slot) => 
          slot.startTime != timeSlot.startTime || 
          slot.endTime != timeSlot.endTime
      ).toList();
      
      _availability[index] = AvailableTimeSlot(
        day: daySlot.day,
        slots: newSlots,
      );
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}