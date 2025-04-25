import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
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
  // Add the missing _isLoading variable
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Delay focus-related operations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This ensures the widget is fully built before any focus operations
      if (mounted) setState(() {});
    });
  }

  // Add this to your state class variables at the top
  final FocusNode reasonFocusNode = FocusNode();

// Then in your dispose method:
  @override
  void dispose() {
    reasonController.dispose();
    reasonFocusNode.dispose(); // Don't forget to dispose the focus node
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),

          // Date Selection
          Text(
            'Select Date',
            style: AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                selectedDate != null
                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : 'Choose a date',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                    selectedTimeSlot =
                        null; // Reset time slot when date changes
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Time Slot Selection
          if (selectedDate != null) ...[
            Text(
              'Select Time Slot',
              style: AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.doctor.doctorProfile?.availableTimeSlots
                      .expand((slot) => slot.slots)
                      .map((timeSlot) {
                    final slotText =
                        '${timeSlot.startTime} - ${timeSlot.endTime}';
                    return ChoiceChip(
                      label: Text(slotText),
                      selected: selectedTimeSlot == slotText,
                      onSelected: (selected) {
                        setState(() {
                          selectedTimeSlot = selected ? slotText : null;
                        });
                      },
                    );
                  }).toList() ??
                  [],
            ),
            const SizedBox(height: 24),
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
            decoration: const InputDecoration(
              hintText: 'Briefly describe your symptoms or reason for visit',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Consultation Fee
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consultation Fee',
                  style: AppStyles.bodyText1,
                ),
                Text(
                  'Rs. ${widget.doctor.doctorProfile?.consultationFees ?? 0}',
                  style: AppStyles.heading2.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Book Button
          ElevatedButton(
            onPressed: _canBook()
                ? () async {
                    // Validate inputs first
                    if (selectedDate == null ||
                        selectedTimeSlot == null ||
                        reasonController.text.trim().isEmpty) {
                      _safeShowSnackBar(
                          context, 'Please fill in all required fields');
                      return;
                    }

                    // Show loading indicator
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final appointmentProvider =
                          context.read<AppointmentProvider>();

                      // Extract the time from the timeSlot (e.g., "09:00 - 12:00" -> "09:00")
                      final startTime =
                          selectedTimeSlot!.split(' - ').first.trim();

                      // Format the appointment date with time as required by the backend
                      final dateComponents = selectedDate
                          .toString()
                          .split(' ')[0]; // Get YYYY-MM-DD
                      final fullDateTime =
                          '$dateComponents $startTime:00'; // Format: YYYY-MM-DD HH:MM:00

                      print("Booking appointment with datetime: $fullDateTime");

                      // Get the appointment details
                      final result = await appointmentProvider.bookAppointment(
                        doctorId: widget.doctor.id,
                        appointmentDate: selectedDate!,
                        timeSlot: selectedTimeSlot!,
                        reason: reasonController.text.trim(),
                        amount:
                            widget.doctor.doctorProfile?.consultationFees ?? 0,
                      );

                      // Hide loading indicator
                      setState(() {
                        _isLoading = false;
                      });

                      if (result) {
                        // Success
                        if (context.mounted) {
                          Navigator.pop(context);
                          _safeShowSnackBar(
                              context, 'Appointment requested successfully!');
                        }
                      } else {
                        // Error
                        if (context.mounted) {
                          _safeShowSnackBar(
                              context,
                              appointmentProvider.error ??
                                  'Failed to book appointment');
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
                : null,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('Book Appointment'),
          ),
          const SizedBox(height: 16), // Bottom padding for safe area
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
