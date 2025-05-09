import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/features/doctor_calendar/provider/todo_provider.dart';
import 'package:mediconnect/features/doctor_calendar/screens/working_hours_settings.dart';
import 'package:mediconnect/features/doctor_calendar/widgets/schedule_day_dialog.dart';
import 'package:mediconnect/features/doctor_calendar/widgets/todo_dialog.dart';
import 'package:mediconnect/features/doctor_calendar/widgets/todo_list_item.dart';
import 'package:mediconnect/shared/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/todo_model.dart';
import '../../auth/providers/auth_provider.dart';


class DoctorCalendarScreen extends StatefulWidget {
  static const String routeName = '/doctor/calendar';

  const DoctorCalendarScreen({Key? key}) : super(key: key);

  @override
  State<DoctorCalendarScreen> createState() => _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends State<DoctorCalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isLoading = false;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    // Load data after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      
      final doctorId = authProvider.user!.id;

      // Calculate first and last day of the month
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      // Load calendar data for this month
      await calendarProvider.fetchCalendar(
        doctorId: doctorId,
        startDate: firstDay,
        endDate: lastDay,
      );

      // Load todos for this month
      await todoProvider.fetchTodos(
        startDate: firstDay,
        endDate: lastDay,
      );
      
      _updateEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateEvents() {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    
    final Map<DateTime, List<dynamic>> newEvents = {};
    
    // Add appointments and schedule events
    if (calendarProvider.calendar != null) {
      for (final schedule in calendarProvider.calendar!.schedule) {
        final date = DateTime(
          schedule.date.year, 
          schedule.date.month, 
          schedule.date.day
        );
        
        if (newEvents[date] == null) {
          newEvents[date] = [];
        }
        
        // Add slots (bookings, blocks)
        for (final slot in schedule.slots) {
          if (slot.isBooked || slot.isBlocked) {
            newEvents[date]!.add(slot);
          }
        }
        
        // Add holiday indicator
        if (schedule.isHoliday) {
          newEvents[date]!.add('Holiday');
        }
      }
    }
    
    // Add todo events
    for (final todo in todoProvider.todos) {
      final date = DateTime(
        todo.date.year, 
        todo.date.month, 
        todo.date.day
      );
      
      if (newEvents[date] == null) {
        newEvents[date] = [];
      }
      
      newEvents[date]!.add(todo);
    }
    
    setState(() {
      _events = newEvents;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dateWithoutTime = DateTime(day.year, day.month, day.day);
    return _events[dateWithoutTime] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, WorkingHoursSettingsScreen.routeName)
                .then((_) => _loadData()); // Refresh data when coming back
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                _buildCalendar(),
                const SizedBox(height: 8),
                _buildSelectedDayInfo(),
                Expanded(child: _buildEventsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        
        // Load data for new month
        final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
        final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final doctorId = authProvider.user!.id;
        
        // Load data for the new month
        Provider.of<CalendarProvider>(context, listen: false).fetchCalendar(
          doctorId: doctorId,
          startDate: firstDay,
          endDate: lastDay,
        ).then((_) {
          Provider.of<TodoProvider>(context, listen: false).fetchTodos(
            startDate: firstDay,
            endDate: lastDay,
          ).then((_) {
            _updateEvents();
          });
        });
      },
    );
  }

  Widget _buildSelectedDayInfo() {
    final selectedDateString = "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}";
    final events = _getEventsForDay(_selectedDay);
    final todosCount = events.whereType<Todo>().length;
    final bookedSlotsCount = events.whereType<CalendarTimeSlot>().where((slot) => slot.isBooked).length;
    final isHoliday = events.contains('Holiday');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Selected: $selectedDateString",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (isHoliday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Holiday",
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(width: 8),
          if (todosCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$todosCount ${todosCount == 1 ? 'Task' : 'Tasks'}",
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          const SizedBox(width: 8),
          if (bookedSlotsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$bookedSlotsCount ${bookedSlotsCount == 1 ? 'Appointment' : 'Appointments'}",
                style: TextStyle(color: Colors.green.shade800),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return const Center(
        child: Text("No events for this day"),
      );
    }
    
    // Group events by type
    final todos = events.whereType<Todo>().toList();
    final slots = events.whereType<CalendarTimeSlot>().toList();
    final isHoliday = events.contains('Holiday');
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Holiday section
            if (isHoliday)
              _buildHolidaySection(),
              
            // Appointments section
            if (slots.isNotEmpty) ...[
              const Text(
                "Appointments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSlotsList(slots),
              const SizedBox(height: 16),
            ],
            
            // Tasks section
            if (todos.isNotEmpty) ...[
              const Text(
                "Tasks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTodoList(todos),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaySection() {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    final daySchedule = calendarProvider.getScheduleForDate(_selectedDay);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_busy, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      "Holiday",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Change"),
                      onPressed: () => _editDaySchedule(),
                    ),
                  ],
                ),
                if (daySchedule?.holidayReason != null && 
                    daySchedule!.holidayReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Reason: ${daySchedule.holidayReason!}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSlotsList(List<CalendarTimeSlot> slots) {
    return Column(
      children: slots.map((slot) {
        final bool isBooked = slot.isBooked;
        final bool isBlocked = slot.isBlocked;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isBlocked ? Icons.block : 
              isBooked ? Icons.event_busy : Icons.event_available,
              color: isBlocked ? Colors.red : 
                     isBooked ? Colors.orange : Colors.green,
            ),
            title: Text("${slot.startTime} - ${slot.endTime}"),
            subtitle: Text(
              isBlocked ? "Blocked" : 
              isBooked ? "Booked" : "Available",
            ),
            trailing: isBlocked ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _unblockTimeSlot(slot.id!),
            ) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTodoList(List<Todo> todos) {
    return Column(
      children: todos.map((todo) {
        return TodoListItem(
          todo: todo,
          onToggle: () => _toggleTodoStatus(todo),
          onEdit: () => _showEditTodoDialog(todo),
          onDelete: () => _deleteTodo(todo),
        );
      }).toList(),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.task),
                title: const Text('Add Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTodoDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Schedule Day'),
                onTap: () {
                  Navigator.pop(context);
                  _editDaySchedule();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block Time Slot'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockTimeSlotDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: const Text('Mark as Holiday'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsHoliday();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTodoDialog(
          selectedDate: _selectedDay,
          onSave: (todo) async {
            try {
              final todoProvider = Provider.of<TodoProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              
              // Set the doctorId from current user
              final todoWithDoctorId = Todo(
                doctorId: authProvider.user!.id,
                date: todo.date,
                title: todo.title,
                description: todo.description,
                priority: todo.priority,
                completed: false,
                time: todo.time,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await todoProvider.createTodo(todoWithDoctorId);
              _updateEvents();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task added successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add task: $e')),
              );
            }
          },
        );
      },
    );
  }

  void _showEditTodoDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTodoDialog(
          selectedDate: _selectedDay,
          existingTodo: todo,
          onSave: (updatedTodo) async {
            try {
              final todoProvider = Provider.of<TodoProvider>(context, listen: false);
              
              if (todo.id != null) {
                await todoProvider.updateTodo(todo.id!, updatedTodo);
                _updateEvents();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task updated successfully')),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update task: $e')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _toggleTodoStatus(Todo todo) async {
    try {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      
      if (todo.id != null) {
        await todoProvider.toggleTodoStatus(todo.id!);
        _updateEvents();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task status: $e')),
      );
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    try {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      
      if (todo.id != null) {
        await todoProvider.deleteTodo(todo.id!);
        _updateEvents();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $e')),
      );
    }
  }

  void _editDaySchedule() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ScheduleDayDialog(
          date: _selectedDay,
          onSave: (slots, isHoliday, holidayReason) async {
            try {
              final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
              
              await calendarProvider.updateDateSchedule(
                date: _selectedDay,
                slots: slots,
                isHoliday: isHoliday,
                holidayReason: holidayReason,
              );
              
              _updateEvents();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule updated successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update schedule: $e')),
              );
            }
          },
        );
      },
    );
  }

  void _showBlockTimeSlotDialog() {
    String startTime = '';
    String endTime = '';
    String? reason;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Block Time Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: const Text('Start Time'),
                      trailing: const Icon(Icons.access_time),
                      subtitle: startTime.isNotEmpty 
                        ? Text(startTime) 
                        : const Text('Select time'),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            startTime = '${picked.hour.toString().padLeft(2, '0')}:'
                                      '${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End Time'),
                      trailing: const Icon(Icons.access_time),
                      subtitle: endTime.isNotEmpty 
                        ? Text(endTime) 
                        : const Text('Select time'),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            endTime = '${picked.hour.toString().padLeft(2, '0')}:'
                                     '${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Reason (optional)',
                      ),
                      onChanged: (value) {
                        reason = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Block'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (startTime.isNotEmpty && endTime.isNotEmpty) {
                      _blockTimeSlot(
                        startTime: startTime,
                        endTime: endTime,
                        reason: reason,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select start and end times')),
                      );
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  Future<void> _blockTimeSlot({
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    try {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      
      await calendarProvider.blockTimeSlot(
        date: _selectedDay,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      
      _updateEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot blocked successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block time slot: $e')),
      );
    }
  }
  
  Future<void> _unblockTimeSlot(String slotId) async {
    try {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      
      await calendarProvider.unblockTimeSlot(
        date: _selectedDay,
        slotId: slotId,
      );
      
      _updateEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot unblocked successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unblock time slot: $e')),
      );
    }
  }
  
  void _markAsHoliday() {
    String? holidayReason;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark as Holiday'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'e.g., Public Holiday, Personal Leave, etc.',
            ),
            onChanged: (value) {
              holidayReason = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Mark'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveAsHoliday(holidayReason);
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _saveAsHoliday(String? holidayReason) async {
    try {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      
      await calendarProvider.updateDateSchedule(
        date: _selectedDay,
        slots: [],
        isHoliday: true,
        holidayReason: holidayReason,
      );
      
      _updateEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Day marked as holiday')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as holiday: $e')),
      );
    }
  }
}