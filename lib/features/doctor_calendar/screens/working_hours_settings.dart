import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/shared/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class WorkingHoursSettingsScreen extends StatefulWidget {
  static const String routeName = '/doctor/working-hours-settings';

  const WorkingHoursSettingsScreen({super.key});

  @override
  State<WorkingHoursSettingsScreen> createState() => _WorkingHoursSettingsScreenState();
}

class _WorkingHoursSettingsScreenState extends State<WorkingHoursSettingsScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  List<DefaultWorkingHours> _workingHours = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      
      if (calendarProvider.calendar != null && 
          calendarProvider.calendar!.defaultWorkingHours.isNotEmpty) {
        // Use existing working hours
        setState(() {
          _workingHours = List<DefaultWorkingHours>.from(
            calendarProvider.calendar!.defaultWorkingHours
          );
        });
      } else {
        // Create default working hours for all days
        setState(() {
          _workingHours = _days.map((day) {
            return DefaultWorkingHours(
              day: day,
              isWorking: day != 'Saturday' && day != 'Sunday',
              slots: day != 'Saturday' && day != 'Sunday' ? [
                CalendarTimeSlot(
                  startTime: '09:00',
                  endTime: '12:00',
                ),
                CalendarTimeSlot(
                  startTime: '13:00',
                  endTime: '17:00',
                ),
              ] : [],
            );
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load working hours: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWorkingHours() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      
      await calendarProvider.setDefaultWorkingHours(_workingHours);
      
      setState(() {
        _hasChanges = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Working hours saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save working hours: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Working Hours Settings'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveWorkingHours,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _workingHours.length,
              itemBuilder: (ctx, index) {
                final workingHours = _workingHours[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        // Day name
                        Expanded(child: Text(workingHours.day)),
                        
                        // Status tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: workingHours.isWorking ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            workingHours.isWorking ? 'Working' : 'Off',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    subtitle: workingHours.isWorking && workingHours.slots.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_formatSlots(workingHours.slots)),
                          )
                        : null,
                    children: [
                      // Working day toggle
                      SwitchListTile(
                        title: const Text('Working Day'),
                        value: workingHours.isWorking,
                        onChanged: (value) {
                          setState(() {
                            _workingHours[index] = DefaultWorkingHours(
                              day: workingHours.day,
                              isWorking: value,
                              slots: workingHours.slots,
                            );
                            _hasChanges = true;
                          });
                        },
                      ),
                      
                      if (workingHours.isWorking) ...[
                        const Divider(),
                        
                        // Time slots section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Time Slots',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('${workingHours.slots.length} slots'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // List of existing time slots
                              if (workingHours.slots.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    child: Text('No time slots added yet'),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: workingHours.slots.length,
                                  itemBuilder: (ctx, slotIndex) {
                                    final slot = workingHours.slots[slotIndex];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: const Icon(Icons.access_time),
                                        title: Text('${slot.startTime} - ${slot.endTime}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              final newSlots = List<CalendarTimeSlot>.from(workingHours.slots);
                                              newSlots.removeAt(slotIndex);
                                              
                                              _workingHours[index] = DefaultWorkingHours(
                                                day: workingHours.day,
                                                isWorking: workingHours.isWorking,
                                                slots: newSlots,
                                              );
                                              
                                              _hasChanges = true;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              
                              // Add slot button
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Time Slot'),
                                  onPressed: () => _showAddTimeSlotDialog(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: _hasChanges ? BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: _saveWorkingHours,
            child: const Text('Save Changes'),
          ),
        ),
      ) : null,
    );
  }

    String _formatSlots(List<CalendarTimeSlot> slots) {
    if (slots.isEmpty) return 'No time slots defined';
    
    final List<String> slotStrings = [];
    for (final slot in slots) {
      slotStrings.add('${slot.startTime} - ${slot.endTime}');
    }
    
    return slotStrings.join(', ');
  }

  void _showAddTimeSlotDialog(int dayIndex) {
    final TextEditingController startController = TextEditingController();
    final TextEditingController endController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Time Slot for ${_workingHours[dayIndex].day}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'Start Time (HH:MM)',
                hintText: '09:00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'End Time (HH:MM)',
                hintText: '17:00',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () {
              final startTime = startController.text.trim();
              final endTime = endController.text.trim();
              
              // Validate input
              if (startTime.isEmpty || endTime.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both start and end times')),
                );
                return;
              }
              
              // Validate time format
              final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
              if (!timeRegex.hasMatch(startTime) || !timeRegex.hasMatch(endTime)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid time format. Use HH:MM (24-hour format)')),
                );
                return;
              }
              
              // Validate start time is before end time
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
              for (final slot in _workingHours[dayIndex].slots) {
                final existingStartParts = slot.startTime.split(':');
                final existingEndParts = slot.endTime.split(':');
                final existingStartHour = int.parse(existingStartParts[0]);
                final existingStartMinute = int.parse(existingStartParts[1]);
                final existingEndHour = int.parse(existingEndParts[0]);
                final existingEndMinute = int.parse(existingEndParts[1]);
                
                if ((startHour < existingEndHour || (startHour == existingEndHour && startMinute < existingEndMinute)) &&
                    (endHour > existingStartHour || (endHour == existingStartHour && endMinute > existingStartMinute))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This time slot overlaps with an existing one')),
                  );
                  return;
                }
              }
              
              // Add new slot
              setState(() {
                final newSlots = List<CalendarTimeSlot>.from(_workingHours[dayIndex].slots);
                newSlots.add(CalendarTimeSlot(
                  startTime: startTime,
                  endTime: endTime,
                ));
                
                // Sort by start time
                newSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
                
                _workingHours[dayIndex] = DefaultWorkingHours(
                  day: _workingHours[dayIndex].day,
                  isWorking: _workingHours[dayIndex].isWorking,
                  slots: newSlots,
                );
                
                _hasChanges = true;
              });
              
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}