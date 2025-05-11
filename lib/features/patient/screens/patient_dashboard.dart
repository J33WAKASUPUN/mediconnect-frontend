import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mediconnect/core/utils/datetime_helper.dart';
import 'package:mediconnect/core/utils/session_helper.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/appointment/widgets/appointment_card.dart';
import 'package:mediconnect/features/notification/providers/notification_provider.dart';
import 'package:mediconnect/features/patient/screens/patient_appointments_screen.dart';
import 'package:mediconnect/shared/constants/app_assets.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_bottom_navigation.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/patient_provider.dart';
import '../widgets/patient_drawer.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => PatientDashboardState();
}

class PatientDashboardState extends State<PatientDashboard> {
  int _currentIndex = 0;

  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const PatientDashboardContent(),
    const PatientAppointmentsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Fix by using a post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Now the context is properly initialized
        final patientProvider =
            Provider.of<PatientProvider>(context as BuildContext, listen: false);
        final appointmentProvider =
            Provider.of<AppointmentProvider>(context as BuildContext, listen: false);
        final notificationProvider =
            Provider.of<NotificationProvider>(context as BuildContext, listen: false);

        patientProvider.getPatientProfile();
        appointmentProvider.loadAppointments();
        notificationProvider.loadNotifications();

        appointmentProvider.syncPaymentStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: context.watch<PatientProvider>().isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentIndex == 0
              ? 'Patient Dashboard'
              : _currentIndex == 1
                  ? 'Appointments'
                  : 'Profile'),
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Badge(
                label: Text(
                  context.watch<NotificationProvider>().unreadCount.toString(),
                ),
                isLabelVisible:
                    context.watch<NotificationProvider>().unreadCount > 0,
                child: const Icon(Icons.notifications),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: const PatientDrawer(),
        body: _screens[_currentIndex],
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          onTap: changeTab,
        ),
      ),
    );
  }
}

class PatientDashboardContent extends StatelessWidget {
  const PatientDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final patientProvider = context.watch<PatientProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();

    // Get patient profile data
    final patientProfile = user?.patientProfile;

    // Current time and session info
    final currentTime = SessionHelper.getCurrentUTC();
    final userLogin = SessionHelper.getUserLogin();

    return RefreshIndicator(
      onRefresh: () async {
        await patientProvider.getPatientProfile();
        await appointmentProvider.loadAppointments();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting and health status
            _buildPatientHeader(context, user),

            // Main dashboard content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Main action buttons
                  _buildMainActionButtons(context),

                  const SizedBox(height: 24),

                  // Health Summary
                  _buildHealthSummarySection(context, patientProfile),

                  const SizedBox(height: 24),

                  // Upcoming Appointments
                  _buildUpcomingAppointments(context, appointmentProvider),

                  const SizedBox(height: 24),

                  // Medication Reminder
                  _buildMedicationReminders(patientProfile),

                  const SizedBox(height: 24),

                  // Medical Records
                  _buildMedicalRecordsSection(),

                  const SizedBox(height: 24),

                  // Wellness Tips
                  _buildWellnessTips(),

                  const SizedBox(height: 24),

                  // Session info
                  _buildSessionInfo(currentTime, userLogin),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context, user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: user?.profilePicture != null
                    ? NetworkImage(user!.profilePicture!)
                    : null,
                child: user?.profilePicture == null
                    ? const Icon(Icons.person,
                        size: 30, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: AppStyles.bodyText2.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                      style: AppStyles.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Health Status: Good',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHealthCard(
                context: context,
                icon: Icons.bloodtype,
                title: 'Blood Type',
                value: user?.patientProfile?.bloodType ?? 'Not set',
              ),
              _buildHealthCard(
                context: context,
                icon: Icons.monitor_heart,
                title: 'Heart Rate',
                value: '72 bpm',
              ),
              _buildHealthCard(
                context: context,
                icon: Icons.water_drop,
                title: 'Blood Sugar',
                value: '90 mg/dL',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard({
    required BuildContext context, // Make sure this is BuildContext not Context
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Card(
        color: Colors.white.withOpacity(0.15),
        elevation: 0,
        margin: const EdgeInsets.only(right: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButtons(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.search,
          label: 'Find Doctor',
          description: 'Search specialists',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/patient/doctors'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.calendar_today,
          label: 'Book Appointment',
          description: 'Schedule a visit',
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, '/patient/doctors'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.message,
          label: 'Consultations',
          description: 'Chat with your doctor',
          color: AppColors.info,
          onTap: () => Navigator.pushNamed(context, '/messages'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.medical_services,
          label: 'Medical Records',
          description: 'View your history',
          color: AppColors.warning,
          onTap: () => Navigator.pushNamed(context, '/patient/medical-records'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthSummarySection(BuildContext context, patientProfile) {
    // Extract data from patient profile
    final bloodType = patientProfile?.bloodType ?? 'Not set';
    final allergies = patientProfile?.allergies ?? [];
    final chronicConditions = patientProfile?.chronicConditions ?? [];
    final lastCheckup = patientProfile?.lastCheckupDate;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Summary',
                  style: AppStyles.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to full health profile
                    Navigator.pushNamed(context, '/profile');
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Update'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHealthInfoRow(
              icon: Icons.bloodtype,
              label: 'Blood Type',
              value: bloodType,
              color: AppColors.error.withOpacity(0.8),
            ),
            const Divider(height: 24),
            _buildHealthInfoRow(
              icon: Icons.sick,
              label: 'Allergies',
              value: allergies.isEmpty ? 'None' : allergies.first,
              moreCount: allergies.length > 1 ? allergies.length - 1 : 0,
              color: AppColors.warning,
            ),
            const Divider(height: 24),
            _buildHealthInfoRow(
              icon: Icons.monitor_heart,
              label: 'Chronic Conditions',
              value:
                  chronicConditions.isEmpty ? 'None' : chronicConditions.first,
              moreCount: chronicConditions.length > 1
                  ? chronicConditions.length - 1
                  : 0,
              color: AppColors.info,
            ),
            const Divider(height: 24),
            _buildHealthInfoRow(
              icon: Icons.calendar_month,
              label: 'Last Checkup',
              value: lastCheckup != null
                  ? DateTimeHelper.formatDate(lastCheckup)
                  : 'Not available',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int moreCount = 0,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (moreCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+$moreCount more',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments(
      BuildContext context, AppointmentProvider appointmentProvider) {
    // Get upcoming appointments sorted by date
    final upcomingAppointments = [...appointmentProvider.upcomingAppointments];
    upcomingAppointments
        .sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    // Take only the next 3 appointments
    final nextAppointments = upcomingAppointments.take(3).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Appointments',
                  style:
                      AppStyles.heading1.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/patient/appointments');
                  },
                  icon: const Icon(Icons.calendar_view_week, size: 16),
                  label: const Text('All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (appointmentProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (nextAppointments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No upcoming appointments',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Book Now',
                        onPressed: () {
                          Navigator.pushNamed(context, '/patient/doctors');
                        },
                        icon: Icons.add,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: nextAppointments.map((appointment) {
                  // Get doctor details
                  final doctorDetails = appointment.doctorDetails;
                  final doctorName = doctorDetails != null
                      ? 'Dr. ${doctorDetails['firstName'] ?? ''} ${doctorDetails['lastName'] ?? ''}'
                      : 'Doctor';

                  // Get specialty if available
                  String specialty = '';
                  if (doctorDetails != null &&
                      doctorDetails['doctorProfile'] != null) {
                    specialty =
                        doctorDetails['doctorProfile']['specialization'] ?? '';
                  }

                  // Format appointment date
                  final formattedDate =
                      DateTimeHelper.formatDate(appointment.appointmentDate);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          doctorName.isNotEmpty
                              ? doctorName.substring(0, 1)
                              : 'D',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        doctorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (specialty.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                specialty,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.timeSlot,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appointment.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appointment.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(appointment.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        // Navigate to appointment details
                        Navigator.pushNamed(
                          context,
                          '/patient/appointment-details',
                          arguments: appointment,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            if (!appointmentProvider.isLoading && nextAppointments.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/patient/doctors');
                  },
                  child: const Text('+ Book New Appointment'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMedicationReminders(patientProfile) {
    // Extract medications from patient profile
    final medications = patientProfile?.currentMedications ?? [];

    final medicationItems = [
      {
        'name': medications.isNotEmpty ? medications[0] : 'Paracetamol',
        'dosage': '500mg',
        'schedule': 'Twice daily',
        'time': '08:00 AM, 08:00 PM',
        'isActive': true,
      },
      if (medications.length > 1)
        {
          'name': medications[1],
          'dosage': '250mg',
          'schedule': 'Once daily',
          'time': '09:00 AM',
          'isActive': true,
        }
      else
        {
          'name': 'Multivitamin',
          'dosage': '1 tablet',
          'schedule': 'Once daily',
          'time': '09:00 AM',
          'isActive': true,
        },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication Reminders',
                  style:
                      AppStyles.heading1.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to medication management
                    Navigator.pushNamed(context as BuildContext, '/patient/medications');
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Medication list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medicationItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final medication = medicationItems[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dosage: ${medication['dosage']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              medication['schedule'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              'Time: ${medication['time']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: medication['isActive'] as bool,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          // Toggle reminder in real app
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsSection() {
    // Sample medical records
    final records = [
      {
        'title': 'General Checkup',
        'date': '2025-04-15',
        'doctor': 'Dr. Sarah Johnson',
      },
      {
        'title': 'Blood Test Results',
        'date': '2025-03-22',
        'doctor': 'Dr. Michael Chen',
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medical Records',
                  style:
                      AppStyles.heading1.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to all medical records
                    Navigator.pushNamed(context as BuildContext, '/patient/medical-records');
                  },
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Records list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = records[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      record['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              record['date'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              record['doctor'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.download,
                        color: AppColors.secondary,
                      ),
                      onPressed: () {
                        // Download function
                      },
                    ),
                    onTap: () {
                      // Navigate to record details
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessTips() {
    // Sample wellness tips
    final tips = [
      {
        'title': 'Stay Hydrated',
        'description':
            'Drink at least 8 glasses of water daily to maintain good health.',
        'icon': Icons.water_drop,
        'color': AppColors.info,
      },
      {
        'title': 'Exercise Regularly',
        'description':
            'Aim for at least 30 minutes of moderate exercise daily.',
        'icon': Icons.fitness_center,
        'color': AppColors.success,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wellness Tips',
              style: AppStyles.heading1.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Tips list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (tip['color'] as Color).withOpacity(0.05),
                    border: Border.all(
                      color: (tip['color'] as Color).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (tip['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tip['icon'] as IconData,
                          color: tip['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip['description'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(String currentTime, String userLogin) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.security,
              size: 20,
              color: Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time: $currentTime | ID: $userLogin',
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
    );
  }
}
