import 'package:flutter/material.dart';
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
  State<AppointmentBookingSheet> createState() => _AppointmentBookingSheetState();
}

class _AppointmentBookingSheetState extends State<AppointmentBookingSheet> {
  DateTime? selectedDate;
  String? selectedTimeSlot;
  final reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
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
                    selectedTimeSlot = null; // Reset time slot when date changes
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
                  })
                  .toList() ??
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
                ? () {
                    // TODO: Implement booking logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment booked successfully!'),
                      ),
                    );
                  }
                : null,
            child: const Text('Book Appointment'),
          ),
          const SizedBox(height: 16), // Bottom padding for safe area
        ],
      ),
    );
  }

  bool _canBook() {
    return selectedDate != null &&
        selectedTimeSlot != null &&
        reasonController.text.isNotEmpty;
  }
}