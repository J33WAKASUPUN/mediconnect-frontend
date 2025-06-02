import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/core/models/todo_model.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/features/doctor_calendar/provider/todo_provider.dart';
import 'package:mediconnect/features/doctor_calendar/screens/working_hours_settings.dart';
import 'package:mediconnect/features/doctor_calendar/widgets/schedule_day_dialog.dart';
import 'package:mediconnect/features/doctor_calendar/widgets/todo_dialog.dart';
import 'package:mediconnect/features/doctor_calendar/widgets/todo_list_item.dart';
import 'package:mediconnect/shared/widgets/loading_indicator.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../auth/providers/auth_provider.dart';

class DoctorCalendarScreen extends StatefulWidget {
  static const String routeName = '/doctor/calendar';

  const DoctorCalendarScreen({super.key});

  @override
  State<DoctorCalendarScreen> createState() => _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends State<DoctorCalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isLoading = false;
  Map<DateTime, List<dynamic>> _events = {};
  bool _showCalendarView = true;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final calendarProvider =
          Provider.of<CalendarProvider>(context, listen: false);
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);

      final doctorId = authProvider.user!.id;

      // Get first and last day of the selected month for proper monthly metrics
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      await calendarProvider.fetchCalendar(
        doctorId: doctorId,
        startDate: firstDay,
        endDate: lastDay,
      );

      await todoProvider.fetchTodos(
        startDate: firstDay,
        endDate: lastDay,
      );

      _updateEvents();
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateEvents() {
    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    final Map<DateTime, List<dynamic>> newEvents = {};

    if (calendarProvider.calendar != null) {
      for (final schedule in calendarProvider.calendar!.schedule) {
        final date = DateTime(
            schedule.date.year, schedule.date.month, schedule.date.day);

        if (newEvents[date] == null) {
          newEvents[date] = [];
        }

        for (final slot in schedule.slots) {
          if (slot.isBooked || slot.isBlocked) {
            newEvents[date]!.add(slot);
          }
        }

        if (schedule.isHoliday) {
          newEvents[date]!.add('Holiday');
        }
      }
    }

    for (final todo in todoProvider.todos) {
      final date = DateTime(todo.date.year, todo.date.month, todo.date.day);

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

  // Get metrics for current month using the dashboard's calculation logic
  int _getMarkedHolidays() {
    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);
    if (calendarProvider.calendar == null) return 0;

    final currentMonth = _focusedDay.month;
    final currentYear = _focusedDay.year;

    return calendarProvider.calendar!.schedule
        .where((day) =>
            day.isHoliday &&
            day.date.month == currentMonth &&
            day.date.year == currentYear)
        .length;
  }

  int _getTotalTasks() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final currentMonth = _focusedDay.month;
    final currentYear = _focusedDay.year;

    return todoProvider.todos
        .where((todo) =>
            todo.date.month == currentMonth && todo.date.year == currentYear)
        .length;
  }

  // Calculate work days in current month, accounting for holidays - FIXED VERSION
  // int _getWorkedDays() {
  //   final calendarProvider =
  //       Provider.of<CalendarProvider>(context, listen: false);
  //   if (calendarProvider.calendar == null) return 0;

  //   final currentMonth = _focusedDay.month;
  //   final currentYear = _focusedDay.year;

  //   // Get today's date for comparison
  //   final now = DateTime.now();

  //   // Check if we're viewing the current month/year or a different month
  //   final isCurrentMonthAndYear =
  //       now.month == currentMonth && now.year == currentYear;

  //   // For current month, count days up to today; for other months, count all days
  //   final lastDayToCount = isCurrentMonthAndYear
  //       ? now.day
  //       : DateTime(currentYear, currentMonth + 1, 0).day; // Last day of month

  //   int workDays = 0;

  //   // Create a set of holiday dates for quick lookup
  //   final Set<int> holidayDays = calendarProvider.calendar!.schedule
  //       .where((day) =>
  //           day.date.month == currentMonth &&
  //           day.date.year == currentYear &&
  //           day.isHoliday)
  //       .map((day) => day.date.day)
  //       .toSet();

  //   // Check each day of the month up to today or end of month
  //   for (int day = 1; day <= lastDayToCount; day++) {
  //     final date = DateTime(currentYear, currentMonth, day);

  //     // Skip weekends (Saturday = 6, Sunday = 7)
  //     if (date.weekday >= 6) continue;

  //     // Skip holidays
  //     if (holidayDays.contains(day)) continue;

  //     // Check if there's a schedule entry for this day
  //     bool hasSchedule = false;

  //     // If it's the first day of the month and it's today, count it as a worked day
  //     // This matches the dashboard's behavior
  //     if (day == 1 && isCurrentMonthAndYear && day == now.day) {
  //       hasSchedule = true;
  //     } else {
  //       // Otherwise check for actual scheduled slots
  //       hasSchedule = calendarProvider.calendar!.schedule.any((schedule) =>
  //           schedule.date.day == day &&
  //           schedule.date.month == currentMonth &&
  //           schedule.date.year == currentYear &&
  //           !schedule.isHoliday &&
  //           schedule.slots.isNotEmpty);
  //     }

  //     // If there's a schedule or it's today (and the first of the month), count it as a work day
  //     if (hasSchedule) {
  //       workDays++;
  //     }
  //   }

  //   return workDays;
  // }

  // Add this method to get completed tasks count
  int _getCompletedTasks() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final currentMonth = _focusedDay.month;
    final currentYear = _focusedDay.year;

    return todoProvider.todos
        .where((todo) =>
            todo.date.month == currentMonth &&
            todo.date.year == currentYear &&
            todo.completed)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: LoadingIndicator(),
                  ))
                : Column(
                    children: [
                      _buildMonthlyStats(),
                      _buildCalendarCard(width),
                      _buildSelectedDayInfo(),
                      _buildEventsList(),
                      const SizedBox(height: 100),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddMenu,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.7),
                AppColors.primary,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, WorkingHoursSettingsScreen.routeName)
                .then((_) => _loadData());
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh calendar',
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildMonthlyStats() {
    final currentMonth = _focusedDay.month;
    final monthName = [
      '',
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
    ][currentMonth];

    // Get the last day of the month to show total days
    final daysInMonth =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;

    // Get today's day if we're in the current month, otherwise the last day of month
    final now = DateTime.now();
    final currentDay =
        (now.month == _focusedDay.month && now.year == _focusedDay.year)
            ? now.day
            : daysInMonth;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName ${_focusedDay.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Show current day progress
                Text(
                  'Day $currentDay/$daysInMonth',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.event_busy,
                title: 'Holidays',
                value: _getMarkedHolidays().toString(),
                color: Colors.purple,
              ),
              _buildStatCard(
                icon: Icons.task_alt,
                title: 'Tasks',
                value: '${_getCompletedTasks()}/${_getTotalTasks()}',
                color: Colors.blue,
              ),
              // _buildStatCard(
              //   icon: Icons.work,
              //   title: 'Work Days',
              //   value: _getWorkedDays().toString(),
              //   color: Colors.green,
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(double width) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Toggle view button
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCalendarView = !_showCalendarView;
                    });
                  },
                  icon: Icon(
                    _showCalendarView ? Icons.list : Icons.calendar_view_month,
                    size: 16,
                  ),
                  label: Text(
                    _showCalendarView ? 'List View' : 'Calendar View',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          _showCalendarView ? _buildCalendarGridView() : _buildTableCalendar(),
        ],
      ),
    );
  }

  Widget _buildCalendarGridView() {
    final now = _focusedDay;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;

    // Get holidays and special days
    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);

    // Create sets for quick lookup
    final holidays = <int>{};
    final bookedDays = <int>{};
    final todoDays = <int>{};

    if (calendarProvider.calendar != null) {
      for (var day in calendarProvider.calendar!.schedule) {
        if (day.date.month == now.month && day.date.year == now.year) {
          if (day.isHoliday) {
            holidays.add(day.date.day);
          } else if (day.slots.any((slot) => slot.isBooked)) {
            bookedDays.add(day.date.day);
          }
        }
      }
    }

    // Add days with todos
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    for (var todo in todoProvider.todos) {
      if (todo.date.month == now.month && todo.date.year == now.year) {
        todoDays.add(todo.date.day);
      }
    }

    return Column(
      children: [
        // Calendar header - month navigation
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: AppColors.primary,
                onPressed: () {
                  setState(() {
                    _focusedDay =
                        DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                  _loadData();
                },
              ),
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: AppColors.primary,
                onPressed: () {
                  setState(() {
                    _focusedDay =
                        DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                  _loadData();
                },
              ),
            ],
          ),
        ),

        // Weekday headers
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

        // Calendar grid
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
              if (index < (firstWeekdayOfMonth - 1)) {
                return const SizedBox.shrink();
              }

              final day = index - (firstWeekdayOfMonth - 1) + 1;
              final isToday = day == DateTime.now().day &&
                  now.month == DateTime.now().month &&
                  now.year == DateTime.now().year;
              final isHoliday = holidays.contains(day);
              final isBooked = bookedDays.contains(day);
              final hasTodo = todoDays.contains(day);
              final isSelected = _selectedDay.day == day &&
                  _selectedDay.month == now.month &&
                  _selectedDay.year == now.year;

              final cellDate = DateTime(now.year, now.month, day);
              final isPastDate = cellDate
                  .isBefore(DateTime.now().subtract(const Duration(days: 1)));

              // Styling
              Color bgColor = Colors.transparent;
              Color textColor =
                  isPastDate ? Colors.grey.shade400 : Colors.black87;
              FontWeight fontWeight = FontWeight.normal;

              if (isSelected) {
                bgColor = AppColors.primary;
                textColor = Colors.white;
                fontWeight = FontWeight.bold;
              } else if (isToday) {
                bgColor = Colors.blue.shade100;
                textColor = Colors.blue.shade700;
                fontWeight = FontWeight.bold;
              } else if (isHoliday) {
                bgColor = Colors.red.withOpacity(0.1);
                textColor = Colors.red.shade700;
              } else if (isBooked) {
                bgColor = Colors.green.withOpacity(0.1);
                textColor = Colors.green.shade800;
              } else if (hasTodo) {
                bgColor = Colors.orange.withOpacity(0.1);
                textColor = Colors.orange.shade800;
              }

              // Check if it's a weekend
              final isWeekend = cellDate.weekday >= 6; // Saturday or Sunday
              if (isWeekend &&
                  !isSelected &&
                  !isToday &&
                  !isHoliday &&
                  !isBooked &&
                  !hasTodo) {
                textColor = Colors.red.shade300;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = DateTime(now.year, now.month, day);
                  });
                },
                child: Stack(
                  children: [
                    // Day cell
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
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

                    // Indicator dots
                    if (isBooked || hasTodo || isHoliday)
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isHoliday) _buildDot(Colors.red),
                            if (isBooked) _buildDot(Colors.green),
                            if (hasTodo) _buildDot(Colors.orange),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(
                  'Today', Colors.blue.shade100, Colors.blue.shade700),
              _buildLegendItem('Selected', AppColors.primary, Colors.white),
              _buildLegendItem(
                  'Holiday', Colors.red.withOpacity(0.1), Colors.red.shade700),
              _buildLegendItem('Appointment', Colors.green.withOpacity(0.1),
                  Colors.green.shade800),
              _buildLegendItem('Task', Colors.orange.withOpacity(0.1),
                  Colors.orange.shade800),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: bgColor == Colors.transparent
                ? Border.all(color: textColor)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTableCalendar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
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
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: Colors.red.shade600),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppColors.primary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppColors.primary,
          ),
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
          _loadData();
        },
      ),
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

  Widget _buildSelectedDayInfo() {
    final selectedDateString =
        "${_selectedDay.day} ${_getMonthName(_selectedDay.month)} ${_selectedDay.year}";
    final events = _getEventsForDay(_selectedDay);
    final todosCount = events.whereType<Todo>().length;
    final completedTodosCount =
        events.whereType<Todo>().where((todo) => todo.completed).length;
    final bookedSlotsCount = events
        .whereType<CalendarTimeSlot>()
        .where((slot) => slot.isBooked)
        .length;
    final isHoliday = events.contains('Holiday');

    // Check if selected day is a weekend
    final isWeekend = _selectedDay.weekday >= 6; // Saturday or Sunday

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDateString,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isHoliday)
                      Text(
                        'Holiday',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      )
                    else if (isWeekend)
                      Text(
                        'Weekend',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _editDaySchedule,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isHoliday)
                _buildEventBadge(
                  "Holiday",
                  Colors.red,
                  Icons.event_busy,
                ),
              if (todosCount > 0)
                _buildEventBadge(
                  "$completedTodosCount/$todosCount ${todosCount == 1 ? 'Task' : 'Tasks'}",
                  Colors.orange,
                  Icons.task,
                ),
              if (bookedSlotsCount > 0)
                _buildEventBadge(
                  "$bookedSlotsCount ${bookedSlotsCount == 1 ? 'Appointment' : 'Appointments'}",
                  Colors.green,
                  Icons.event,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                color: Colors.grey.shade400,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "No events for this day",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddMenu,
                icon: const Icon(Icons.add),
                label: const Text("Add Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final todos = events.whereType<Todo>().toList();
    final slots = events.whereType<CalendarTimeSlot>().toList();
    final isHoliday = events.contains('Holiday');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (isHoliday) _buildHolidaySection(),
          if (slots.isNotEmpty) _buildSlotsSection(slots),
          if (todos.isNotEmpty) _buildTodosSection(todos),
        ],
      ),
    );
  }

  Widget _buildHolidaySection() {
    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);
    final daySchedule = calendarProvider.getScheduleForDate(_selectedDay);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Holiday header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
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
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_busy,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Holiday",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.red.shade700, size: 20),
                  tooltip: 'Edit',
                  onPressed: _editDaySchedule,
                ),
              ],
            ),
          ),
          if (daySchedule?.holidayReason != null &&
              daySchedule!.holidayReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reason:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daySchedule.holidayReason!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotsSection(List<CalendarTimeSlot> slots) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appointments header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
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
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Appointments",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green, size: 20),
                  tooltip: 'Block time',
                  onPressed: _showBlockTimeSlotDialog,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: slots.map((slot) => _buildSlotCard(slot)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(CalendarTimeSlot slot) {
    final bool isBooked = slot.isBooked;
    final bool isBlocked = slot.isBlocked;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isBlocked
              ? Colors.red.shade200
              : isBooked
                  ? Colors.orange.shade200
                  : Colors.green.shade200,
          width: 1,
        ),
      ),
      color: isBlocked
          ? Colors.red.shade50
          : isBooked
              ? Colors.orange.shade50
              : Colors.green.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isBlocked
                ? Colors.red.withOpacity(0.2)
                : isBooked
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isBlocked
                ? Icons.block
                : isBooked
                    ? Icons.event_busy
                    : Icons.event_available,
            color: isBlocked
                ? Colors.red
                : isBooked
                    ? Colors.orange
                    : Colors.green,
            size: 18,
          ),
        ),
        title: Text(
          "${slot.startTime} - ${slot.endTime}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isBlocked
              ? "Blocked"
              : isBooked
                  ? "Booked"
                  : "Available",
        ),
        trailing: isBlocked
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Unblock',
                onPressed: () => _unblockTimeSlot(slot.id!),
              )
            : null,
      ),
    );
  }

  Widget _buildTodosSection(List<Todo> todos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tasks header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
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
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.task,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Tasks",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.orange, size: 20),
                  tooltip: 'Add task',
                  onPressed: _showAddTodoDialog,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: todos
                  .map((todo) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: TodoListItem(
                          todo: todo,
                          onToggle: () => _toggleTodoStatus(todo),
                          onEdit: () => _showEditTodoDialog(todo),
                          onDelete: () => _deleteTodo(todo),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildMenuOption(
                  icon: Icons.task,
                  title: 'Add Task',
                  subtitle: 'Create a new task or reminder',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showAddTodoDialog();
                  },
                ),
                _buildMenuOption(
                  icon: Icons.event,
                  title: 'Schedule Day',
                  subtitle: 'Set working hours and availability',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _editDaySchedule();
                  },
                ),
                _buildMenuOption(
                  icon: Icons.block,
                  title: 'Block Time Slot',
                  subtitle: 'Mark time as unavailable',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showBlockTimeSlotDialog();
                  },
                ),
                _buildMenuOption(
                  icon: Icons.event_busy,
                  title: 'Mark as Holiday',
                  subtitle: 'Set entire day as holiday',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _markAsHoliday();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for handling events
  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTodoDialog(
          selectedDate: _selectedDay,
          onSave: (todo) async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            try {
              final todoProvider =
                  Provider.of<TodoProvider>(context, listen: false);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);

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

              if (mounted) {
                _updateEvents();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Task added successfully'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to add task: $e'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
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
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            try {
              final todoProvider =
                  Provider.of<TodoProvider>(context, listen: false);

              if (todo.id != null) {
                await todoProvider.updateTodo(todo.id!, updatedTodo);

                if (mounted) {
                  _updateEvents();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('Task updated successfully'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update task: $e'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
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

        if (mounted) {
          _updateEvents();
        }
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);

      if (todo.id != null) {
        await todoProvider.deleteTodo(todo.id!);

        if (mounted) {
          _updateEvents();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Task deleted successfully'),
              backgroundColor: Colors.blue.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _editDaySchedule() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ScheduleDayDialog(
          date: _selectedDay,
          onSave: (slots, isHoliday, holidayReason) async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            try {
              final calendarProvider =
                  Provider.of<CalendarProvider>(context, listen: false);

              await calendarProvider.updateDateSchedule(
                date: _selectedDay,
                slots: slots,
                isHoliday: isHoliday,
                holidayReason: holidayReason,
              );

              if (mounted) {
                _updateEvents();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Schedule updated successfully'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update schedule: $e'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
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
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                  // Block time header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
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
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.block,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Block Time Slot',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimePickerTile(
                          'Start Time',
                          startTime,
                          (time) => setState(() => startTime = time),
                        ),
                        const SizedBox(height: 16),
                        _buildTimePickerTile(
                          'End Time',
                          endTime,
                          (time) => setState(() => endTime = time),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Reason (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                          onChanged: (value) => reason = value,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  Navigator.of(context).pop();

                                  if (startTime.isNotEmpty &&
                                      endTime.isNotEmpty) {
                                    _blockTimeSlot(
                                      startTime: startTime,
                                      endTime: endTime,
                                      reason: reason,
                                    );
                                  } else {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Please select start and end times'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Block'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildTimePickerTile(
      String title, String selectedTime, Function(String) onTimeSelected) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title),
        trailing: const Icon(Icons.access_time),
        subtitle: selectedTime.isNotEmpty
            ? Text(selectedTime)
            : const Text('Select time'),
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 9, minute: 0),
          );
          if (picked != null) {
            final timeString = '${picked.hour.toString().padLeft(2, '0')}:'
                '${picked.minute.toString().padLeft(2, '0')}';
            onTimeSelected(timeString);
          }
        },
      ),
    );
  }

  Future<void> _blockTimeSlot({
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final calendarProvider =
          Provider.of<CalendarProvider>(context, listen: false);

      await calendarProvider.blockTimeSlot(
        date: _selectedDay,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );

      if (mounted) {
        _updateEvents();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Time slot blocked successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to block time slot: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _unblockTimeSlot(String slotId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final calendarProvider =
          Provider.of<CalendarProvider>(context, listen: false);

      await calendarProvider.unblockTimeSlot(
        date: _selectedDay,
        slotId: slotId,
      );

      if (mounted) {
        _updateEvents();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Time slot unblocked successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to unblock time slot: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _markAsHoliday() {
    String? holidayReason;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
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
                // Holiday header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
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
                          color: Colors.purple.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy,
                          color: Colors.purple.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mark as Holiday',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected date: ${_selectedDay.day} ${_getMonthName(_selectedDay.month)} ${_selectedDay.year}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          hintText: 'e.g., Public Holiday, Personal Leave',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onChanged: (value) => holidayReason = value,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _saveAsHoliday(holidayReason);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Mark as Holiday'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAsHoliday(String? holidayReason) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final calendarProvider =
          Provider.of<CalendarProvider>(context, listen: false);

      await calendarProvider.updateDateSchedule(
        date: _selectedDay,
        slots: [],
        isHoliday: true,
        holidayReason: holidayReason,
      );

      if (mounted) {
        _updateEvents();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Day marked as holiday'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to mark as holiday: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
