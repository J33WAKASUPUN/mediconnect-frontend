import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mediconnect/core/utils/datetime_helper.dart';
import 'package:mediconnect/core/utils/session_helper.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/appointment/widgets/appointment_card.dart';
import 'package:mediconnect/features/doctor/screens/doctor_appointments_screen.dart';
import 'package:mediconnect/features/messages/screens/message_screen.dart';
import 'package:mediconnect/features/notification/providers/notification_provider.dart';
import 'package:mediconnect/features/profile/providers/profile_provider.dart';
import 'package:mediconnect/shared/constants/app_assets.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/doctor_provider.dart';
import '../widgets/doctor_drawer.dart';
import '../../profile/screens/profile_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => DoctorDashboardState();
}

class DoctorDashboardState extends State<DoctorDashboard> {
  int _currentIndex = 0;
  bool _isLoading = false;

  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  // Define screens for each tab
  late final List<Widget> _screens = [
    const DoctorDashboardContent(),
    const DoctorScheduleScreen(),
    const ProfileScreen(),
    const MessagesScreen(),
    const DoctorAppointmentsScreen(),
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
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      // First load profile data to ensure doctor profile is available
      await profileProvider.getProfile();

      // Then load doctor-specific data
      await doctorProvider.getDoctorProfile();

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
      isLoading: _isLoading || context.watch<DoctorProvider>().isLoading,
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
                isLabelVisible: context.watch<NotificationProvider>().unreadCount > 0,
                child: const Icon(Icons.notifications),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: const DoctorDrawer(),
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildCustomBottomNavigation(),
      ),
    );
  }
  
  Widget _buildCustomBottomNavigation() {
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
              _buildNavItem(1, Icons.calendar_today_outlined, 'Schedule'),
              // Center space for profile
              const SizedBox(width: 70),
              _buildNavItem(3, Icons.chat_bubble_outline, 'Messages'),
              _buildNavItem(4, Icons.people_alt_outlined, 'Appointments'),
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
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Create a placeholder for DoctorScheduleScreen
class DoctorScheduleScreen extends StatelessWidget {
  const DoctorScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Schedule',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your working hours and availability',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Add schedule management functionality
              },
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Set Availability'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorDashboardContent extends StatefulWidget {
  const DoctorDashboardContent({super.key});

  @override
  State<DoctorDashboardContent> createState() => _DoctorDashboardContentState();
}

class _DoctorDashboardContentState extends State<DoctorDashboardContent> {
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
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);

      // Explicitly load profile data to ensure it's available
      await profileProvider.getProfile();
      
      // Then load doctor-specific data
      await doctorProvider.getDoctorProfile();
      
      // Then load appointments
      await appointmentProvider.loadAppointments();
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
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final doctorProvider = context.watch<DoctorProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    // Current time and session info
    final currentTime = SessionHelper.getCurrentUTC();
    final userLogin = SessionHelper.getUserLogin();

    // Get user from auth provider
    final user = authProvider.user;
    
    // Get doctor profile data with fallback, like patient dashboard does
    final doctorProfile = user?.doctorProfile;

    // Calculate metrics from appointment data
    final totalAppointments = appointmentProvider.appointments.length;
    final completedAppointments = appointmentProvider.appointments
        .where((apt) => apt.status == 'completed')
        .length;
    final cancelledAppointments = appointmentProvider.appointments
        .where((apt) => apt.status == 'cancelled')
        .length;
    final pendingAppointments = appointmentProvider.appointments
        .where((apt) => apt.status == 'pending')
        .length;
    final todayAppointments = appointmentProvider.todayAppointments.length;

    // Get stat values with appropriate fallbacks
    final specialization = doctorProfile?.specialization ?? 'Medical Professional';
    final experience = doctorProfile?.yearsOfExperience ?? 0;
    final patientCount = doctorProvider.patientCount;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting and doctor info
            _buildProfileHeader(user, todayAppointments, specialization, experience, patientCount),

            // Main dashboard content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // KPI cards
                  _buildMetricsOverview(
                    todayAppointments: todayAppointments,
                    totalPatients: totalAppointments,
                    completedAppointments: completedAppointments,
                    pendingAppointments: pendingAppointments,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Appointments analytics
                  _buildAppointmentAnalytics(
                    context,
                    completed: completedAppointments,
                    cancelled: cancelledAppointments,
                    pending: pendingAppointments,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Today's appointments
                  _buildTodayAppointments(context, appointmentProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Recent patients section
                  _buildRecentPatients(context, appointmentProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons section
                  _buildQuickActions(context),
                  
                  const SizedBox(height: 24),
                  
                  // Session info at bottom
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

  // New profile header styled like the patient dashboard
  Widget _buildProfileHeader(user, int todayAppointments, String specialization, int experience, int patientCount) {
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
              // Doctor profile picture with border
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
                              : 'D',
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
                      'Dr. ${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Badge showing appointments
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
                          Text(
                            '$todayAppointments appointment${todayAppointments != 1 ? 's' : ''} today',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
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
                icon: Icons.people,
                title: 'Patients',
                value: patientCount.toString(),
              ),
              _buildHealthCard(
                icon: Icons.medical_services,
                title: 'Specialization',
                value: specialization,
              ),
              _buildHealthCard(
                icon: Icons.star,
                title: 'Experience',
                value: '$experience yrs',
              ),
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsOverview({
    required int todayAppointments,
    required int totalPatients,
    required int completedAppointments,
    required int pendingAppointments,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: AppStyles.heading1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Today's\nAppointments",
                value: todayAppointments.toString(),
                icon: Icons.calendar_today,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: _buildMetricCard(
                title: "Total\nPatients",
                value: totalPatients.toString(),
                icon: Icons.people,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Completed\nConsultations",
                value: completedAppointments.toString(),
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
            Expanded(
              child: _buildMetricCard(
                title: "Pending\nAppointments",
                value: pendingAppointments.toString(),
                icon: Icons.pending_actions,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentAnalytics(
    BuildContext context,
    {required int completed, required int cancelled, required int pending}
  ) {
    final total = completed + cancelled + pending;
    final completedPercentage = total > 0 ? completed / total * 100 : 0;
    final cancelledPercentage = total > 0 ? cancelled / total * 100 : 0;
    final pendingPercentage = total > 0 ? pending / total * 100 : 0;

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
              'Appointment Summary',
              style: AppStyles.heading1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: completedPercentage.toDouble(),
                            title: '${completedPercentage.toStringAsFixed(0)}%',
                            color: AppColors.success,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: cancelledPercentage.toDouble(),
                            title: '${cancelledPercentage.toStringAsFixed(0)}%',
                            color: AppColors.error,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: pendingPercentage.toDouble(),
                            title: '${pendingPercentage.toStringAsFixed(0)}%',
                            color: AppColors.warning,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        startDegreeOffset: 180,
                      ),
                    ),
                  ),
                  
                  // Legend
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                            color: AppColors.success,
                            label: 'Completed',
                            value: completed.toString(),
                          ),
                          const SizedBox(height: 16),
                          _buildLegendItem(
                            color: AppColors.error,
                            label: 'Cancelled',
                            value: cancelled.toString(),
                          ),
                          const SizedBox(height: 16),
                          _buildLegendItem(
                            color: AppColors.warning,
                            label: 'Pending',
                            value: pending.toString(),
                          ),
                        ],
                      ),
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayAppointments(
    BuildContext context,
    AppointmentProvider appointmentProvider
  ) {
    // Get today's appointments sorted by time
    final todayAppointments = [...appointmentProvider.todayAppointments];
    todayAppointments.sort((a, b) {
      // Extract start time from timeSlot format "HH:MM - HH:MM"
      final aStartTime = a.timeSlot.split(' - ').first;
      final bStartTime = b.timeSlot.split(' - ').first;
      return aStartTime.compareTo(bStartTime);
    });

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
                  'Today\'s Appointments',
                  style: AppStyles.heading1.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/doctor/appointments');
                  },
                  icon: const Icon(Icons.calendar_view_day, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            
            if (appointmentProvider.isLoading || _isRefreshing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (todayAppointments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No appointments scheduled for today',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayAppointments.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final appointment = todayAppointments[index];
                  
                  // Get patient name
                  final patientName = appointment.patientDetails != null
                      ? '${appointment.patientDetails!['firstName'] ?? ''} ${appointment.patientDetails!['lastName'] ?? ''}'
                      : 'Patient';
                  
                  // Get initials for avatar
                  final initials = patientName.isNotEmpty
                      ? patientName.split(' ').take(2).map((name) => name.isNotEmpty ? name[0] : '').join()
                      : 'P';
                  
                  // Determine status color
                  Color statusColor;
                  IconData statusIcon;
                  switch(appointment.status) {
                    case 'confirmed':
                      statusColor = AppColors.success;
                      statusIcon = Icons.check_circle;
                      break;
                    case 'pending':
                      statusColor = AppColors.warning;
                      statusIcon = Icons.pending;
                      break;
                    case 'cancelled':
                      statusColor = AppColors.error;
                      statusIcon = Icons.cancel;
                      break;
                    default:
                      statusColor = Colors.grey;
                      statusIcon = Icons.schedule;
                  }
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              appointment.timeSlot,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        if (appointment.reason != null && appointment.reason!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Reason: ${appointment.reason}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                appointment.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      // Navigate to appointment details
                      Navigator.pushNamed(
                        context,
                        '/doctor/appointment-details',
                        arguments: appointment,
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPatients(
    BuildContext context,
    AppointmentProvider appointmentProvider
  ) {
    // Get unique patients from completed appointments
    final Map<String, dynamic> uniquePatients = {};
    
    for (var appointment in appointmentProvider.appointments) {
      if (appointment.patientId != null && 
          appointment.patientDetails != null &&
          !uniquePatients.containsKey(appointment.patientId)) {
        uniquePatients[appointment.patientId] = {
          'details': appointment.patientDetails,
          'lastAppointment': appointment.appointmentDate,
        };
      }
    }
    
    // Sort patients by most recent appointment and take top 5
    final sortedPatients = uniquePatients.entries.toList()
      ..sort((a, b) => (b.value['lastAppointment'] as DateTime)
          .compareTo(a.value['lastAppointment'] as DateTime));
    
    final recentPatients = sortedPatients.take(5).toList();

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
                  'Recent Patients',
                  style: AppStyles.heading1.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to all patients view
                  },
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            
            if (recentPatients.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'No patient records found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentPatients.length,
                separatorBuilder: (context, index) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final patientId = recentPatients[index].key;
                  final patientData = recentPatients[index].value;
                  final patientDetails = patientData['details'] as Map<String, dynamic>;
                  final lastAppointment = patientData['lastAppointment'] as DateTime;
                  
                  // Format patient name
                  final firstName = patientDetails['firstName'] ?? '';
                  final lastName = patientDetails['lastName'] ?? '';
                  final fullName = '$firstName $lastName'.trim();
                  final patientName = fullName.isNotEmpty ? fullName : 'Patient';
                  
                  // Format last appointment date
                  final lastAppointmentDate = DateTimeHelper.formatDate(lastAppointment);
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withOpacity(0.2),
                      child: Text(
                        patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      patientName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Last visit: $lastAppointmentDate',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.medical_information, size: 20),
                          color: AppColors.secondary,
                          onPressed: () {
                            // View medical records for this patient
                            Navigator.pushNamed(
                              context,
                              '/doctor/patient-records',
                              arguments: patientId,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.message_outlined, size: 20),
                          color: AppColors.primary,
                          onPressed: () {
                            // Start chat with this patient
                            Navigator.pushNamed(
                              context,
                              '/messages',
                              arguments: patientId,
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to patient details
                      Navigator.pushNamed(
                        context,
                        '/doctor/patient-details',
                        arguments: patientId,
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppStyles.heading1.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context: context,
                icon: Icons.calendar_month,
                label: 'Manage Calendar',
                onTap: () => Navigator.pushNamed(context, '/doctor/calendar'),
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: _buildQuickActionButton(
                context: context,
                icon: Icons.add_circle_outline,
                label: 'Create Record',
                onTap: () => Navigator.pushNamed(context, '/doctor/create-record'),
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context: context,
                icon: Icons.message_outlined,
                label: 'Messages',
                onTap: () => Navigator.pushNamed(context, '/messages'),
                color: AppColors.info,
              ),
            ),
            Expanded(
              child: _buildQuickActionButton(
                context: context,
                icon: Icons.analytics_outlined,
                label: 'Statistics',
                onTap: () => Navigator.pushNamed(context, '/doctor/statistics'),
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
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

  String _formatCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    
    return '$dayName, $monthName ${now.day}, ${now.year}';
  }
}