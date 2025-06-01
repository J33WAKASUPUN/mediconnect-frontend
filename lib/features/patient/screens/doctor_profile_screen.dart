import 'package:flutter/material.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/features/review/providers/review_provider.dart';
import 'package:mediconnect/features/review/screens/doctor_review_screen.dart';
import 'package:mediconnect/features/review/widgets/review_card.dart';
import 'package:mediconnect/features/review/widgets/stars_rating.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../widgets/appointment_booking_sheet.dart';
import 'package:provider/provider.dart';

class DoctorProfileScreen extends StatelessWidget {
  final User doctor;

  const DoctorProfileScreen({
    super.key,
    required this.doctor,
  });

  // Colors matching your dashboard
  static const Color primaryColor = Color(0xFF4D4DFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: CustomScrollView(
        slivers: [
          // Sliver app bar with doctor profile
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: primaryColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: doctor.profilePicture != null
                          ? NetworkImage(doctor.profilePicture!)
                          : null,
                      child: doctor.profilePicture == null
                          ? Text(
                              'Dr. ${doctor.firstName[0]}${doctor.lastName[0]}',
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dr. ${doctor.firstName} ${doctor.lastName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (doctor.doctorProfile?.specialization != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          doctor.doctorProfile!.specialization!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share doctor profile')),
                  );
                },
              ),
            ],
          ),
          
          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 120, // Extra padding for FABs
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick action cards (removed Call button)
                  Row(
                    children: [
                      _buildQuickActionCard(
                        context,
                        icon: Icons.calendar_today,
                        label: 'Book',
                        color: Colors.green,
                        onTap: () => _showBookingBottomSheet(context),
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.message_outlined,
                        label: 'Message',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(context, '/messages');
                        },
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.star_border,
                        label: 'Reviews',
                        color: Colors.amber,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorReviewsScreen(
                                doctorId: doctor.id,
                                doctorName:
                                    'Dr. ${doctor.firstName} ${doctor.lastName}',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Contact Information
                  _buildSectionCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone_outlined,
                    iconColor: Colors.blue,
                    children: [
                      _buildInfoRow('Email', doctor.email),
                      _buildInfoRow('Phone', doctor.phoneNumber),
                      _buildInfoRow('Address', doctor.address),
                    ],
                  ),

                  // Professional Information
                  if (doctor.doctorProfile != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Professional Information',
                      icon: Icons.medical_services_outlined,
                      iconColor: Colors.green,
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
                      _buildSectionCard(
                        title: 'Education',
                        icon: Icons.school_outlined,
                        iconColor: Colors.orange,
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
                      _buildSectionCard(
                        title: 'Hospital Affiliations',
                        icon: Icons.local_hospital_outlined,
                        iconColor: Colors.red,
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
                      _buildSectionCard(
                        title: 'Expertise',
                        icon: Icons.psychology_outlined,
                        iconColor: Colors.purple,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                doctor.doctorProfile!.expertise.map((expertise) {
                              return Chip(
                                label: Text(expertise),
                                backgroundColor: primaryColor.withOpacity(0.1),
                                labelStyle: const TextStyle(color: primaryColor),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],

                    // Patient Reviews
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Patient Reviews',
                      icon: Icons.star_outline,
                      iconColor: Colors.amber,
                      children: [
                        _buildReviewsSection(context),
                      ],
                      padding: const EdgeInsets.only(
                        top: 16, left: 16, right: 16, bottom: 8
                      ),
                    ),

                    // Available Time Periods
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Available Time Periods',
                      icon: Icons.access_time,
                      iconColor: Colors.teal,
                      padding: const EdgeInsets.only(
                        top: 16, left: 16, right: 16, bottom: 8
                      ),
                      children: [
                        _buildCalendarSection(context),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _showBookingBottomSheet(context),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.calendar_today),
          label: const Text(
            'Book Appointment',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // Bottom navigation bar like in your dashboard
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1, // Assuming Doctors is selected
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Doctors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Appointments',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // More rounded
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16), // Slightly more padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Slightly larger
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24, // Slightly larger icon
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    return FutureBuilder(
      future: reviewProvider.loadDoctorReviews(doctor.id, limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Consumer<ReviewProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (provider.error != null && provider.doctorReviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Error: ${provider.error}'),
                    ],
                  ),
                ),
              );
            }

            if (provider.doctorReviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20), // More rounded
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          StarRating(
                            rating: provider.averageRating,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Based on ${provider.totalReviews} reviews',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to see all reviews',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reviews preview (3 max)
                ...provider.doctorReviews.take(3).map((review) {
                  return ReviewCard(
                    review: review,
                    isDoctorView: false,
                  );
                }),

                const SizedBox(height: 16),

                // View all button if there are more reviews
                if (provider.totalReviews > 3)
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorReviewsScreen(
                              doctorId: doctor.id,
                              doctorName:
                                  'Dr. ${doctor.firstName} ${doctor.lastName}',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // More rounded
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('View All Reviews'),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildCalendarSection(BuildContext context) {
    return FutureBuilder(
      future: context.read<CalendarProvider>().fetchCalendar(
            doctorId: doctor.id,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 30)),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Consumer<CalendarProvider>(
          builder: (context, provider, child) {
            // If we have calendar data, use that
            if (provider.calendar != null) {
              // If there are no working days, show a message
              final workingDays = provider
                  .calendar!.defaultWorkingHours
                  .where((day) =>
                      day.isWorking && day.slots.isNotEmpty)
                  .toList();

              if (workingDays.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'This doctor has not set their working hours yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Weekly schedule
                  ...workingDays.map((day) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20), // More rounded
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16), // Increased padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, 
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25), // More rounded
                                  ),
                                  child: Text(
                                    day.day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: day.slots.map((time) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16), // More rounded
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    '${time.startTime} - ${time.endTime}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Upcoming holidays
                  if (provider.calendar!.schedule
                      .where((day) =>
                          day.isHoliday &&
                          day.date.isAfter(DateTime.now()) &&
                          day.date.isBefore(DateTime.now()
                              .add(const Duration(days: 30))))
                      .isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(20), // Increased padding
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20), // More rounded
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event_busy, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Upcoming Unavailable Dates',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...provider.calendar!.schedule
                              .where((day) =>
                                  day.isHoliday &&
                                  day.date.isAfter(DateTime.now()) &&
                                  day.date.isBefore(DateTime.now()
                                      .add(const Duration(days: 30))))
                              .map((holiday) {
                                final dateStr =
                                    '${holiday.date.day}/${holiday.date.month}/${holiday.date.year}';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12, 
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16), // More rounded
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.red, size: 16),
                                      const SizedBox(width: 12),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      if (holiday.holidayReason != null) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '- ${holiday.holidayReason}',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
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
              );
            } else {
              // If we don't have calendar data, show a message
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Doctor\'s schedule information is not available at the moment.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showBookingBottomSheet(BuildContext context) {
    FocusScope.of(context).unfocus();

    Future.delayed(const Duration(milliseconds: 50), () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Much more rounded for modern look
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20), // Increased padding
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Slightly larger
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16), // More rounded
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22, // Slightly larger
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100), // Lighter divider
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12), // Increased padding
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100, // Lighter border
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600, // Slightly lighter
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600, // Slightly bolder
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}