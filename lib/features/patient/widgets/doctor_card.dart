import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import 'doctor_action_dialog.dart';

class DoctorCard extends StatelessWidget {
  final User doctor;

  const DoctorCard({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showActionDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 4),
                    Text(
                      doctor.email,
                      style: AppStyles.bodyText2,
                    ),
                    const SizedBox(height: 4),
                    if (doctor.doctorProfile?.specialization != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          doctor.doctorProfile!.specialization!,
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (doctor.doctorProfile?.yearsOfExperience != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${doctor.doctorProfile!.yearsOfExperience} years of experience',
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DoctorActionDialog(doctor: doctor),
    );
  }
}