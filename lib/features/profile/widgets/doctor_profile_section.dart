import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/utils/datetime_helper.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../providers/profile_provider.dart';

class DoctorProfileSection extends StatefulWidget {
  final DoctorProfile? profile;

  const DoctorProfileSection({
    super.key,
    required this.profile,
  });

  @override
  State<DoctorProfileSection> createState() => _DoctorProfileSectionState();
}

class _DoctorProfileSectionState extends State<DoctorProfileSection> {
  bool _isEditing = false;
  late DoctorProfile _editingProfile;
  bool _isLoadingCalendar = false;
  bool _showCalendarView = false;

  @override
  void initState() {
    super.initState();
    _initializeProfile();

    // Make this synchronous to ensure it happens immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // First reset the calendar provider to ensure clean state
        final calendarProvider =
            Provider.of<CalendarProvider>(context, listen: false);
        calendarProvider.resetState();

        // Then immediately load the calendar data
        _loadCalendarDataImmediately();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if calendar data is already loaded
    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);
    if (calendarProvider.calendar == null && !_isLoadingCalendar) {
      // Try loading calendar data again if it's not already loaded
      _loadCalendarData();
    }
  }

  @override
  void didUpdateWidget(DoctorProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _initializeProfile();
      print("DoctorProfileSection updated with new profile");
    }
  }

  void _loadCalendarDataImmediately() {
    if (widget.profile == null) return;

    setState(() {
      _isLoadingCalendar = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      print('Loading calendar for doctorId: $userId immediately');

      // Use a separate method for immediate loading
      _fetchCalendarAndRefresh(userId, startDate, endDate);
    }
  }

  void _initializeProfile() {
    // When initializing, maintain profile data but set availableTimeSlots to empty
    _editingProfile = widget.profile?.clone() ?? DoctorProfile();
    _editingProfile.availableTimeSlots = []; // Always set to empty list
  }

  Future<void> _fetchCalendarAndRefresh(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final calendarProvider =
          Provider.of<CalendarProvider>(context, listen: false);

      // Force a refresh to ensure we get fresh data
      final calendar = await calendarProvider.fetchCalendar(
        doctorId: userId,
        startDate: startDate,
        endDate: endDate,
        forceRefresh: true, // Force refresh to ensure data is loaded
      );

      // Force setState to ensure UI updates regardless of notifyListeners
      if (mounted) {
        setState(() {
          _isLoadingCalendar = false;
        });

        // Extra notification to be absolutely sure
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          calendarProvider.forceCalendarRefresh();
        }
      }
    } catch (e) {
      print('Error in _fetchCalendarAndRefresh: $e');
      if (mounted) {
        setState(() {
          _isLoadingCalendar = false;
        });
      }
    }
  }

  // Load calendar data for the current doctor
  Future<void> _loadCalendarData() async {
    if (widget.profile == null) return;

    setState(() {
      _isLoadingCalendar = true;
    });

    try {
      // Get the authenticated user's ID (which should be the doctor's ID)
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId != null) {
        // Calculate date range for current month (or next 30 days)
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);
        final endDate = DateTime(now.year, now.month + 1, 0);

        // Load calendar data again regardless of whether the provider has it or not
        final calendarProvider = context.read<CalendarProvider>();
        await calendarProvider.fetchCalendar(
          doctorId: userId,
          startDate: startDate,
          endDate: endDate,
          forceRefresh: true, // Force it to refresh the data
        );

        // Force refresh UI explicitly
        if (mounted) {
          setState(() {
            // Just triggering setState is enough to force a rebuild
          });
        }
      }
    } catch (e) {
      print('Error loading calendar data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCalendar = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      // Since we're not using availableTimeSlots anymore, make sure it's empty
      _editingProfile.availableTimeSlots = [];

      await context
          .read<ProfileProvider>()
          .updateDoctorProfile(_editingProfile);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Professional information updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Basic Information
            if (_isEditing)
              // Editing mode - show text fields
              Column(
                children: [
                  CustomTextField(
                    label: 'Specialization',
                    initialValue: _editingProfile.specialization,
                    enabled: true,
                    onChanged: (value) {
                      setState(() => _editingProfile.specialization = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'License Number',
                    initialValue: _editingProfile.licenseNumber,
                    enabled: true,
                    onChanged: (value) {
                      setState(() => _editingProfile.licenseNumber = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Years of Experience',
                    initialValue: _editingProfile.yearsOfExperience?.toString(),
                    enabled: true,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _editingProfile.yearsOfExperience =
                          int.tryParse(value));
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Consultation Fees',
                    initialValue: _editingProfile.consultationFees?.toString(),
                    enabled: true,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _editingProfile.consultationFees =
                          double.tryParse(value));
                    },
                  ),
                ],
              )
            else
              // View mode - show as regular text rows
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'Specialization:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(_editingProfile.specialization ??
                              'Not specified'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'License Number:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                              _editingProfile.licenseNumber ?? 'Not specified'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'Years of Experience:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                              _editingProfile.yearsOfExperience?.toString() ??
                                  'Not specified'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'Consultation Fees:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: _editingProfile.consultationFees != null
                              ? Text(
                                  'Rs. ${_editingProfile.consultationFees?.toString()}')
                              : const Text('Not specified'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Education
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Education',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.education.isEmpty)
                  const Text(
                    "No education information available",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ..._editingProfile.education.map((edu) => Card(
                      child: ListTile(
                        title: Text(edu.degree),
                        subtitle: Text('${edu.institution} (${edu.year})'),
                        trailing: _isEditing
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _editingProfile.education.remove(edu);
                                  });
                                },
                              )
                            : null,
                      ),
                    )),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Education',
                    onPressed: _addEducation,
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Hospital Affiliations
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital Affiliations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.hospitalAffiliations.isEmpty)
                  const Text(
                    "No hospital affiliations listed",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ..._editingProfile.hospitalAffiliations
                    .map((affiliation) => Card(
                          child: ListTile(
                            title: Text(affiliation.hospitalName),
                            subtitle: Text(
                                '${affiliation.role} (Since ${DateTimeHelper.formatDate(affiliation.startDate)})'),
                            trailing: _isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _editingProfile.hospitalAffiliations
                                            .remove(affiliation);
                                      });
                                    },
                                  )
                                : null,
                          ),
                        )),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Hospital Affiliation',
                    onPressed: _addHospitalAffiliation,
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Expertise
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Areas of Expertise',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.expertise.isEmpty)
                  const Text(
                    "No areas of expertise listed",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ...List.generate(_editingProfile.expertise.length, (index) {
                  final exp = _editingProfile.expertise[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(exp)),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _editingProfile.expertise.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Expertise',
                    onPressed: () => _addItem('Expertise', (value) {
                      setState(() => _editingProfile.expertise.add(value));
                    }),
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Working Hours Calendar Section with enhanced styling
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
                          'Working Hours',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (!_isEditing)
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
                    else
                      Consumer<CalendarProvider>(
                        builder: (context, calendarProvider, child) {
                          // Print debug info for troubleshooting
                          print(
                              'Consumer rebuilding: calendar=${calendarProvider.calendar != null}, loading=${calendarProvider.isLoading}');

                          final calendar = calendarProvider.calendar;

                          if (calendar == null || calendarProvider.isLoading) {
                            return Column(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: calendarProvider.isLoading
                                        ? const CircularProgressIndicator()
                                        : const Text(
                                            'No calendar data available. Set up your working hours in the Calendar section.',
                                            style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey),
                                          ),
                                  ),
                                ),
                                // Add a button for manual refresh
                                if (!calendarProvider.isLoading)
                                  CustomButton(
                                    text: 'Load Calendar Data',
                                    onPressed: () => _loadCalendarData(),
                                    isSecondary: true,
                                    icon: Icons.refresh,
                                  ),
                              ],
                            );
                          }

                          // If we get here, we have calendar data
                          if (_showCalendarView) {
                            return _buildCalendarGridView(calendarProvider);
                          } else {
                            return _buildWorkingHoursList(calendar);
                          }
                        },
                      ),

                    // Link to full calendar management
                    if (!_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: CustomButton(
                            text: 'Manage Calendar',
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/doctor/calendar',
                              ).then((_) {
                                // Refresh calendar data when returning from calendar screen
                                _loadCalendarData();
                              });
                            },
                            isSecondary: false,
                            icon: Icons.calendar_month,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: _isEditing ? 'Save Changes' : 'Edit Information',
                    onPressed: () {
                      if (_isEditing) {
                        _saveChanges();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                    icon: _isEditing ? Icons.save : Icons.edit,
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _initializeProfile();
                        });
                      },
                      isSecondary: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Build working hours list from calendar data with enhanced styling
  Widget _buildWorkingHoursList(DoctorCalendar calendar) {
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
                children: calendar.defaultWorkingHours.map((day) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              day.day,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
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
                }).toList(),
              ),
            ],
          ),
        ),

        // Special schedule changes
        if (calendar.schedule.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Special Schedule Changes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          
          // Holidays section
          if (calendar.schedule.any((day) => day.isHoliday)) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Holidays',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...calendar.schedule
                    .where((day) => day.isHoliday)
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
                ],
              ),
            ),
          ],
          
          // Special days with custom slots
          ...calendar.schedule
            .where((day) => !day.isHoliday && day.slots.isNotEmpty)
            .map((specialDay) {
              final dateStr = DateTimeHelper.formatDate(specialDay.date);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  title: Text(dateStr),
                  subtitle: Text(
                    '${specialDay.slots.length} custom time slot(s)',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                  leading: Icon(Icons.event_note, color: Colors.orange.shade800),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: specialDay.slots.map((slot) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${slot.startTime} - ${slot.endTime}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: slot.isBlocked
                              ? const Text('Blocked',
                                  style: TextStyle(color: Colors.orange))
                              : const Text('Available'),
                            leading: Icon(
                              slot.isBlocked ? Icons.block : Icons.access_time,
                              color: slot.isBlocked ? Colors.orange : Colors.green,
                              size: 18,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ],
    );
  }

  // NEW: Build calendar grid view with enhanced styling matching booking sheet
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
            
            // Determine the date for this cell
            final cellDate = DateTime(now.year, now.month, day);
            final isPastDate = cellDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
            
            Color bgColor = Colors.transparent;
            Color textColor = isPastDate ? Colors.grey.shade400 : Colors.black;
            Color borderColor = Colors.grey.withOpacity(0.2);
            FontWeight fontWeight = FontWeight.normal;
            
            if (isToday) {
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

            return Container(
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
              _buildLegendItem('Holiday', Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.3)),
              _buildLegendItem('Special Hours', Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.3)),
            ],
          ),
        ),
      ],
    );
  }

  // Updated legend item builder to match booking sheet style
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

  // Dialog helpers
  Future<void> _addItem(String title, Function(String) onAdd) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddItemDialog(title: title),
    );
    if (result != null && result.isNotEmpty) {
      onAdd(result);
    }
  }

  Future<void> _addEducation() async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) => const _AddEducationDialog(),
    );
    if (result != null) {
      setState(() {
        _editingProfile.education.add(result);
      });
    }
  }

  Future<void> _addHospitalAffiliation() async {
    final result = await showDialog<HospitalAffiliation>(
      context: context,
      builder: (context) => const _AddHospitalAffiliationDialog(),
    );
    if (result != null) {
      setState(() {
        _editingProfile.hospitalAffiliations.add(result);
      });
    }
  }

  // We need to keep this method to avoid errors with dialog references, but we won't expose it in the UI
  Future<void> _addTimeSlot() async {
    final result = await showDialog<AvailableTimeSlot>(
      context: context,
      builder: (context) => const _AddTimeSlotDialog(),
    );
    if (result != null) {
      setState(() {
        // Although we're adding it here, we'll clear this when saving
        _editingProfile.availableTimeSlots.add(result);
      });
    }
  }
}

// Add Item Dialog
class _AddItemDialog extends StatefulWidget {
  final String title;

  const _AddItemDialog({required this.title});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.title}'),
      content: CustomTextField(
        controller: _controller,
        label: widget.title,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Add Education Dialog
class _AddEducationDialog extends StatefulWidget {
  const _AddEducationDialog();

  @override
  State<_AddEducationDialog> createState() => _AddEducationDialogState();
}

class _AddEducationDialogState extends State<_AddEducationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _degreeController = TextEditingController();
  final _institutionController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void dispose() {
    _degreeController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Education'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _degreeController,
              label: 'Degree',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Degree is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _institutionController,
              label: 'Institution',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Institution is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _yearController,
              label: 'Year',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Year is required';
                }
                if (int.tryParse(value!) == null) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                Education(
                  degree: _degreeController.text,
                  institution: _institutionController.text,
                  year: int.parse(_yearController.text),
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Add Hospital Affiliation Dialog
class _AddHospitalAffiliationDialog extends StatefulWidget {
  const _AddHospitalAffiliationDialog();

  @override
  State<_AddHospitalAffiliationDialog> createState() =>
      _AddHospitalAffiliationDialogState();
}

class _AddHospitalAffiliationDialogState
    extends State<_AddHospitalAffiliationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalNameController = TextEditingController();
  final _roleController = TextEditingController();
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Hospital Affiliation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _hospitalNameController,
              label: 'Hospital Name',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Hospital name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _roleController,
              label: 'Role',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Role is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Start Date: ${DateTimeHelper.formatDate(_startDate)}'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: const Text('Select Date'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                HospitalAffiliation(
                  hospitalName: _hospitalNameController.text,
                  role: _roleController.text,
                  startDate: _startDate,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Add Time Slot Dialog
class _AddTimeSlotDialog extends StatefulWidget {
  const _AddTimeSlotDialog();

  @override
  State<_AddTimeSlotDialog> createState() => _AddTimeSlotDialogState();
}

class _AddTimeSlotDialogState extends State<_AddTimeSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDay = 'Monday';
  final List<TimeSlot> _timeSlots = [];

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Available Time Slot'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
              ),
              items: _weekDays
                  .map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(day),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDay = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ..._timeSlots.map((slot) => ListTile(
                  title: Text('${slot.startTime} - ${slot.endTime}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _timeSlots.remove(slot));
                    },
                  ),
                )),
            CustomButton(
              text: 'Add Time Slot',
              onPressed: _addTimeSlot,
              isSecondary: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_timeSlots.isNotEmpty) {
              Navigator.pop(
                context,
                AvailableTimeSlot(
                  day: _selectedDay,
                  slots: _timeSlots,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addTimeSlot() async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (startTime != null) {
      TimeOfDay? endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: startTime.hour + 1,
          minute: startTime.minute,
        ),
      );
      if (endTime != null) {
        setState(() {
          _timeSlots.add(TimeSlot(
            startTime: startTime.format(context),
            endTime: endTime.format(context),
          ));
        });
      }
    }
  }
}