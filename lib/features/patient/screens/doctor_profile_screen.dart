import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../widgets/appointment_booking_sheet.dart';

class DoctorProfileScreen extends StatelessWidget {
  final User doctor;

  const DoctorProfileScreen({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 140, // Extra padding for FABs
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: doctor.profilePicture != null
                        ? NetworkImage(doctor.profilePicture!)
                        : null,
                    child: doctor.profilePicture == null
                        ? Text(
                            'Dr. ${doctor.firstName[0]}${doctor.lastName[0]}',
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dr. ${doctor.firstName} ${doctor.lastName}',
                    style: AppStyles.heading1,
                  ),
                  if (doctor.doctorProfile?.specialization != null)
                    Text(
                      doctor.doctorProfile!.specialization!,
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information
            _buildSection(
              title: 'Contact Information',
              children: [
                _buildInfoRow('Email', doctor.email),
                _buildInfoRow('Phone', doctor.phoneNumber),
                _buildInfoRow('Address', doctor.address),
              ],
            ),

            // Professional Information
            if (doctor.doctorProfile != null) ...[
              const SizedBox(height: 16),
              _buildSection(
                title: 'Professional Information',
                children: [
                  _buildInfoRow(
                    'License Number',
                    doctor.doctorProfile?.licenseNumber ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Experience',
                    '${doctor.doctorProfile?.yearsOfExperience ?? 0} years',
                  ),
                  _buildInfoRow(
                    'Consultation Fee',
                    'Rs. ${doctor.doctorProfile?.consultationFees ?? 0}',
                  ),
                ],
              ),

              // Education
              if (doctor.doctorProfile?.education.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Education',
                  children: doctor.doctorProfile!.education.map((edu) {
                    return _buildInfoRow(
                      edu.degree,
                      '${edu.institution} (${edu.year})',
                    );
                  }).toList(),
                ),
              ],

              // Hospital Affiliations
              if (doctor.doctorProfile?.hospitalAffiliations.isNotEmpty ??
                  false) ...[
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Hospital Affiliations',
                  children: doctor.doctorProfile!.hospitalAffiliations
                      .map((hospital) {
                    return _buildInfoRow(
                      hospital.hospitalName,
                      hospital.role,
                    );
                  }).toList(),
                ),
              ],

              // Expertise
              if (doctor.doctorProfile?.expertise.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Expertise',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          doctor.doctorProfile!.expertise.map((expertise) {
                        return Chip(
                          label: Text(expertise),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: const TextStyle(color: AppColors.primary),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],

              // Available Time Periods
              if (doctor.doctorProfile?.availableTimeSlots.isNotEmpty ??
                  false) ...[
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Available Time Periods',
                  children:
                      doctor.doctorProfile!.availableTimeSlots.map((slot) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.day,
                              style: AppStyles.bodyText1.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: slot.slots.map((time) {
                                return Chip(
                                  label: Text(
                                    '${time.startTime} - ${time.endTime}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'message',
              onPressed: () {
                _safeShowSnackBar(context, 'Messaging feature coming soon!');
              },
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message'),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'appointment',
              onPressed: () => _showBookingBottomSheet(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Book Appointment'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showBookingBottomSheet(BuildContext context) {
    FocusScope.of(context).unfocus(); // First unfocus any current focus

    Future.delayed(const Duration(milliseconds: 50), () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9, // Increase this from 0.7
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => AppointmentBookingSheet(
                doctor: doctor,
                scrollController: scrollController,
              ),
            );
          });
        },
      );
    });
  }

  void _safeShowSnackBar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final snackBar = SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1,
              left: 16,
              right: 16),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    });
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyles.heading2,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyText1,
            ),
          ),
        ],
      ),
    );
  }
}
