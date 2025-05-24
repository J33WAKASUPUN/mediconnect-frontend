import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/core/models/medical_record_model.dart';
import 'package:mediconnect/core/models/profile_models.dart';
import 'package:mediconnect/core/utils/datetime_helper.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/medical_records/providers/medical_records_provider.dart';
import 'package:mediconnect/features/medication_reminder/provider/medication_reminder_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_list_screen.dart';
import 'package:mediconnect/features/notification/providers/notification_provider.dart';
import 'package:mediconnect/features/patient/screens/doctor_list_screen.dart';
import 'package:mediconnect/features/patient/screens/patient_appointments_screen.dart';
import 'package:mediconnect/features/profile/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../shared/constants/colors.dart';
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
  bool _isLoading = false;

  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const PatientDashboardContent(),
    const DoctorsListScreen(),
    const ProfileScreen(userData: {},),
    const ChatListScreen(),
    const PatientAppointmentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Make sure we load data after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // Fixed loading function without using context as BuildContext
  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get providers without using context as BuildContext
      final patientProvider =
          Provider.of<PatientProvider>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false); 
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      // First load profile data to ensure patient profile is available
      await profileProvider.getProfile();

      // Then load patient-specific data
      await patientProvider.getPatientProfile();

      // Then load appointments and notifications
      await appointmentProvider.loadAppointments();
      await appointmentProvider.syncPaymentStatus();
      await notificationProvider.loadNotifications();
    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading || context.watch<PatientProvider>().isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'MediConnect',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
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
        bottomNavigationBar: _buildCompactBottomNavigation(),
      ),
    );
  }
  
  Widget _buildCompactBottomNavigation() {
    return Container(
      height: 65, // More compact height
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Base row with all navigation items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
              _buildNavItem(1, Icons.search, 'Doctors'),
              // Center space for profile
              const SizedBox(width: 70),
              _buildNavItem(3, Icons.chat_bubble_outline, 'Messages'),
              _buildNavItem(4, Icons.calendar_today_outlined, 'Appointments'),
            ],
          ),
          
          // Centered profile button (raised above row)
          Positioned(
            top: -15,
            child: GestureDetector(
              onTap: () => changeTab(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.user;
                        return user?.profilePicture != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(27.5),
                                child: Image.network(
                                  user!.profilePicture!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                                size: 28,
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () => changeTab(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24, // Fixed size - no animation
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w400, // Not bold when selected
            ),
          ),
        ],
      ),
    );
  }
}

class PatientDashboardContent extends StatefulWidget {
  const PatientDashboardContent({super.key});

  @override
  State<PatientDashboardContent> createState() =>
      _PatientDashboardContentState();
}

class _PatientDashboardContentState extends State<PatientDashboardContent> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get profile provider
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      // Explicitly load profile data to ensure it's available
      await profileProvider.getProfile();

      // Then load appointments
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      await appointmentProvider.loadAppointments();

      // Also load medical records
      final medicalRecordsProvider =
          Provider.of<MedicalRecordsProvider>(context, listen: false);
      await medicalRecordsProvider.loadPatientMedicalRecords();
    } catch (e) {
      print("Error refreshing dashboard data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();
    final medicalRecordsProvider = context.watch<MedicalRecordsProvider>();
    final medicationReminderProvider =
        context.watch<MedicationReminderProvider>();

    final user = authProvider.user;
    // Get patient profile data
    PatientProfile? patientProfile = user?.patientProfile;

    // If null, try from profile provider
    patientProfile ??= profileProvider.patientProfile;

    // Ensure medical records are loaded
    if (!medicalRecordsProvider.isLoading &&
        medicalRecordsProvider.records.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          medicalRecordsProvider.loadPatientMedicalRecords();
        }
      });
    }

    // Load medication reminders if medical records are available
    if (!medicalRecordsProvider.isLoading &&
        medicationReminderProvider.reminders.isEmpty &&
        medicalRecordsProvider.records.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          medicationReminderProvider
              .loadMedicationsFromRecords(medicalRecordsProvider.records);
        }
      });
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting and patient info
            _buildPatientHeader(user, patientProfile),

            // Main dashboard content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Main action buttons
                  _buildMainActionButtons(),

                  const SizedBox(height: 24),

                  // Health Summary - Using actual data from patient profile
                  _buildHealthSummarySection(patientProfile),

                  const SizedBox(height: 24),

                  // Upcoming Appointments
                  _buildUpcomingAppointments(appointmentProvider),

                  const SizedBox(height: 24),

                  // Medication Reminder - Now using real data
                  _buildMedicationReminders(patientProfile),

                  const SizedBox(height: 24),

                  // Medical Records - Now using real data
                  _buildMedicalRecordsSection(),

                  const SizedBox(height: 24),

                  // Wellness Tips
                  _buildWellnessTips(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(user, PatientProfile? patientProfile) {
    final bloodType = patientProfile?.bloodType ?? 'Not set';
    final allergies = patientProfile?.allergies ?? [];
    final lastCheckup = patientProfile?.lastCheckupDate;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Larger profile picture with border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 38, // Increased size
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profilePicture != null
                      ? NetworkImage(user!.profilePicture!)
                      : null,
                  child: user?.profilePicture == null
                      ? Text(
                          user != null &&
                                  user.firstName.isNotEmpty &&
                                  user.lastName.isNotEmpty
                              ? '${user.firstName[0]}${user.lastName[0]}'
                              : 'P',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Show appointment count instead of health status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Consumer<AppointmentProvider>(
                            builder: (context, provider, _) {
                              final count =
                                  provider.upcomingAppointments.length;
                              return Text(
                                '$count upcoming appointment${count != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
                icon: Icons.bloodtype,
                title: 'Blood Type',
                value: bloodType,
              ),
              _buildLastCheckupCard(lastCheckup),
              _buildAllergiesCard(allergies: allergies),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard({
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

  // New card showing last checkup date
  Widget _buildLastCheckupCard(DateTime? lastCheckup) {
    String value = 'Not available';
    if (lastCheckup != null) {
      value = DateTimeHelper.formatDate(lastCheckup);
    }

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
                Icons.calendar_month,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                'Last Checkup',
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New card showing allergies count
  Widget _buildAllergiesCard({required List<String> allergies}) {
    String value = allergies.isEmpty ? 'None' : '${allergies.length}';

    return Expanded(
      child: Card(
        color: Colors.white.withOpacity(0.15),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                'Allergies',
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

  Widget _buildMainActionButtons() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionButton(
          icon: Icons.search,
          label: 'Find Doctor',
          description: 'Search specialists',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/patient/doctors'),
        ),
        _buildActionButton(
          icon: Icons.calendar_today,
          label: 'Book Appointment',
          description: 'Schedule a visit',
          color: AppColors.secondary,
          // Use the appointments route here
          onTap: () => Navigator.pushNamed(context, '/patient/appointments'),
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'Consultations',
          description: 'Chat with your doctor',
          color: AppColors.info,
          onTap: () => Navigator.pushNamed(context, '/messages'),
        ),
        _buildActionButton(
          icon: Icons.medical_services,
          label: 'Medical Records',
          description: 'View your history',
          color: AppColors.warning,
          onTap: () => Navigator.pushNamed(context, '/medical-records'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
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

  Widget _buildHealthSummarySection(patientProfile) {
    // Extract actual data from patient profile
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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

  Widget _buildUpcomingAppointments(AppointmentProvider appointmentProvider) {
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
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
            if (appointmentProvider.isLoading || _isRefreshing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (nextAppointments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                          // Fix: use doctors route instead of book-appointment
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
                    // Fix: use doctors route instead of book-appointment
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
    final medicalRecordsProvider = Provider.of<MedicalRecordsProvider>(context);
    final medicationReminderProvider =
        Provider.of<MedicationReminderProvider>(context);

    // Check if we need to load records or reminders
    if (!medicalRecordsProvider.isLoading &&
        medicalRecordsProvider.records.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          medicalRecordsProvider.loadPatientMedicalRecords();
        }
      });
    } else if (!medicationReminderProvider.isLoading &&
        medicationReminderProvider.reminders.isEmpty &&
        medicalRecordsProvider.records.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          medicationReminderProvider
              .loadMedicationsFromRecords(medicalRecordsProvider.records);
        }
      });
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and manage button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/medical-records');
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

            // Content based on loading state
            if (medicalRecordsProvider.isLoading ||
                medicationReminderProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (medicalRecordsProvider.error != null)
              _buildErrorState(medicalRecordsProvider.error!,
                  () => medicalRecordsProvider.loadPatientMedicalRecords())
            else if (medicationReminderProvider.reminders.isEmpty)
              _buildEmptyState()
            else
              _buildMedicationList(medicationReminderProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text('Error loading medications: $error'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: retry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No medications prescribed',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList(MedicationReminderProvider provider) {
    // Take top 3 reminders
    final displayedReminders = provider.reminders.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedReminders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reminder = displayedReminders[index];
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
                      reminder.medicationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dosage: ${reminder.dosage}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.frequency,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              // Important: Use StatefulBuilder to prevent setState during build
              StatefulBuilder(builder: (context, setState) {
                return Switch(
                  value: reminder.isActive,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    // Handle toggle outside of build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.toggleReminder(reminder);
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicalRecordsSection() {
    final medicalRecordsProvider = Provider.of<MedicalRecordsProvider>(context);

    // Load records if not already loaded
    if (!medicalRecordsProvider.isLoading &&
        medicalRecordsProvider.records.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          medicalRecordsProvider.loadPatientMedicalRecords();
        }
      });
    }

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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/medical-records');
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
            if (medicalRecordsProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (medicalRecordsProvider.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.orange, size: 48),
                      const SizedBox(height: 16),
                      Text(
                          'Error loading records: ${medicalRecordsProvider.error}'),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            medicalRecordsProvider.loadPatientMedicalRecords(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildMedicalRecordsList(medicalRecordsProvider.records),
          ],
        ),
      ),
    );
  }

// Helper method to build medical records list
  Widget _buildMedicalRecordsList(List<MedicalRecord> records) {
    // If no records, show placeholder
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No medical records found',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by most recent records first and take top 2
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentRecords = records.take(2).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentRecords.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = recentRecords[index];
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
              record.diagnosis.length > 30
                  ? '${record.diagnosis.substring(0, 30)}...'
                  : record.diagnosis,
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
                      DateFormat('yyyy-MM-dd').format(record.createdAt),
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
                      record.doctorName,
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
                _downloadMedicalRecordPdf(record.id);
              },
            ),
            onTap: () {
              // Navigate to record details
              Navigator.pushNamed(
                context,
                '/medical-records',
                arguments: record.id,
              );
            },
          ),
        );
      },
    );
  }

// Helper method to download record PDF
  void _downloadMedicalRecordPdf(String recordId) async {
    try {
      final medicalRecordsProvider =
          Provider.of<MedicalRecordsProvider>(context, listen: false);

      final pdfUrl = await medicalRecordsProvider.generatePdf(recordId);

      if (pdfUrl != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Opening PDF...')));

        // Logic to open PDF would go here
        // For example, using url_launcher to open the PDF in a browser
      } else {
        throw Exception('Failed to generate PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
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
}
