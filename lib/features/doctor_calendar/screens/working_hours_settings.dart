import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/calendar_model.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/shared/widgets/loading_indicator.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:provider/provider.dart';

class WorkingHoursSettingsScreen extends StatefulWidget {
  static const String routeName = '/doctor/calendar/working-hours';

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
        setState(() {
          _workingHours = List<DefaultWorkingHours>.from(
            calendarProvider.calendar!.defaultWorkingHours
          );
        });
      } else {
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
        SnackBar(
          content: Text('Failed to load working hours: $e'),
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
        SnackBar(
          content: const Text('Working hours saved successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save working hours: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: LoadingIndicator(),
                  ))
                : Column(
                    children: [
                      _buildStatsSummary(),
                      _buildWorkingHoursList(),
                      const SizedBox(height: 100),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _hasChanges ? FloatingActionButton.extended(
        onPressed: _saveWorkingHours,
        icon: const Icon(Icons.save),
        label: const Text('Save Changes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ) : null,
      bottomNavigationBar: _hasChanges 
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _saveWorkingHours,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ) 
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Working Hours',
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
        if (_hasChanges)
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveWorkingHours,
            tooltip: 'Save Changes',
          ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Schedule Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Default Working Hours',
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
                icon: Icons.work,
                title: 'Work Days',
                value: _workingHours.where((wh) => wh.isWorking).length.toString(),
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.schedule,
                title: 'Time Slots',
                value: _workingHours.fold(0, (sum, wh) => sum + wh.slots.length).toString(),
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.weekend,
                title: 'Days Off',
                value: _workingHours.where((wh) => !wh.isWorking).length.toString(),
                color: Colors.orange,
              ),
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

  Widget _buildWorkingHoursList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _workingHours.length,
      itemBuilder: (ctx, index) {
        final workingHours = _workingHours[index];
        
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
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getDayColor(workingHours.day).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getDayIcon(workingHours.day),
                      color: _getDayColor(workingHours.day),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      workingHours.day,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: workingHours.isWorking 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: workingHours.isWorking 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      workingHours.isWorking ? 'Working' : 'Off',
                      style: TextStyle(
                        color: workingHours.isWorking ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: workingHours.isWorking && workingHours.slots.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, left: 42),
                      child: Text(
                        _formatSlots(workingHours.slots),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : null,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Working day toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text(
                            'Working Day',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Set whether you work on ${workingHours.day}s',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          value: workingHours.isWorking,
                          activeColor: AppColors.primary,
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
                      ),
                      
                      if (workingHours.isWorking) ...[
                        const SizedBox(height: 16),
                        
                        // Time slots section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.schedule,
                                        color: Colors.blue.shade700,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Time Slots',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${workingHours.slots.length} ${workingHours.slots.length == 1 ? 'slot' : 'slots'}',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (workingHours.slots.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No time slots added yet',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add working hours for this day',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  itemCount: workingHours.slots.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, slotIndex) {
                                    final slot = workingHours.slots[slotIndex];
                                    return Card(
                                      elevation: 0,
                                      margin: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                          tooltip: 'Remove time slot',
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
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAddTimeSlotDialog(index),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Time Slot'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
      builder: (ctx) => Dialog(
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getDayColor(_workingHours[dayIndex].day).withOpacity(0.1),
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
                        color: _getDayColor(_workingHours[dayIndex].day).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: _getDayColor(_workingHours[dayIndex].day),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add Time Slot for ${_workingHours[dayIndex].day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getDayColor(_workingHours[dayIndex].day),
                        ),
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
                      'Enter working hours in 24-hour format (HH:MM)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeInputField(
                      controller: startController,
                      label: 'Start Time',
                      hint: '09:00',
                    ),
                    const SizedBox(height: 16),
                    _buildTimeInputField(
                      controller: endController,
                      label: 'End Time',
                      hint: '17:00',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                            onPressed: () => _addTimeSlot(dayIndex, startController.text, endController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Add Slot'),
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
      ),
    );
  }

  void _addTimeSlot(int dayIndex, String startTime, String endTime) {
    startTime = startTime.trim();
    endTime = endTime.trim();
    
    // Validate input
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
    
    // Validate time format
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
    
    // Validate start time is before end time
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Time slot added for ${_workingHours[dayIndex].day}'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}