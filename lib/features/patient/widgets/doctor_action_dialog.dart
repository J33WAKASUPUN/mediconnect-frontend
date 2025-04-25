// lib/features/patient/widgets/doctor_action_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class DoctorActionDialog extends StatelessWidget {
  final User doctor;

  const DoctorActionDialog({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Doctor Info Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: doctor.profilePicture != null
                      ? NetworkImage(doctor.profilePicture!)
                      : null,
                  child: doctor.profilePicture == null
                      ? Text(
                          'Dr. ${doctor.firstName[0]}${doctor.lastName[0]}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${doctor.firstName} ${doctor.lastName}',
                        style: AppStyles.heading2,
                      ),
                      if (doctor.doctorProfile?.specialization != null)
                        Text(
                          doctor.doctorProfile!.specialization!,
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),
              title: const Text('View Profile'),
              subtitle: const Text('See detailed information'),
              onTap: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(
                  context,
                  '/doctor/profile',
                  arguments: doctor,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              title: const Text('Book Appointment'),
              subtitle: const Text('Schedule a consultation'),
              onTap: () {
                Navigator.pop(context);
                // Replace SnackBar with proper navigation to the doctor profile
                Navigator.pushNamed(
                  context,
                  '/doctor/profile',
                  arguments: doctor,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.message_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Send Message'),
              subtitle: const Text('Start a conversation'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement messaging
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Messaging feature coming soon!'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
