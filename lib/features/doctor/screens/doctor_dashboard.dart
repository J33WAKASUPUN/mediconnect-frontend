import 'package:flutter/material.dart';
import 'package:mediconnect/core/utils/session_helper.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_bottom_navigation.dart';
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

  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const DoctorDashboardContent(),
    const Center(child: Text('Appointments')), // Placeholder
    const ProfileScreen(),
  ];

  final currentTime = SessionHelper.getCurrentUTC();
  final userLogin = SessionHelper.getUserLogin();

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() => context.read<DoctorProvider>().getDoctorProfile());
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: context.watch<DoctorProvider>().isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentIndex == 0
              ? 'Doctor Dashboard'
              : _currentIndex == 1
                  ? 'Appointments'
                  : 'Profile'),
        ),
        drawer: const DoctorDrawer(),
        body: _screens[_currentIndex],
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

class DoctorDashboardContent extends StatelessWidget {
  const DoctorDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final doctorProvider = context.watch<DoctorProvider>();

    return RefreshIndicator(
      onRefresh: () => doctorProvider.getDoctorProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, user?.firstName ?? ''),
            const SizedBox(height: 24),
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildTodayAppointments(),
            const SizedBox(height: 24),
            _buildRecentPatients(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Dr. $name',
              style: AppStyles.heading1.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Time (UTC): 2025-03-11 17:18:32',
              style: AppStyles.bodyText2.copyWith(
                color: AppColors.textLight.withOpacity(0.8),
              ),
            ),
            Text(
              'ID: J33WAKASUPUN',
              style: AppStyles.bodyText2.copyWith(
                color: AppColors.textLight.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildOverviewCard(
          icon: Icons.calendar_today,
          title: 'Today\'s\nAppointments',
          value: '5',
          color: AppColors.primary,
        ),
        _buildOverviewCard(
          icon: Icons.people,
          title: 'Total\nPatients',
          value: '120',
          color: AppColors.secondary,
        ),
        _buildOverviewCard(
          icon: Icons.access_time,
          title: 'Hours\nWorked',
          value: '6.5',
          color: AppColors.info,
        ),
        _buildOverviewCard(
          icon: Icons.medical_services,
          title: 'Consultations\nCompleted',
          value: '450',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppStyles.bodyText2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppStyles.heading1.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAppointments() {
  return Consumer<AppointmentProvider>(
    builder: (context, provider, child) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final todayAppointments = provider.todayAppointments;
      
      if (todayAppointments.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Appointments', style: AppStyles.heading2),
            const SizedBox(height: 16),
            const Center(
              child: Text('No appointments scheduled for today'),
            ),
          ],
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Today\'s Appointments', style: AppStyles.heading2),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/doctor/appointments');
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayAppointments.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final appointment = todayAppointments[index];
                final patientName = appointment.patientDetails != null
                    ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
                    : 'Patient';
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      patientName.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(patientName),
                  subtitle: Text(appointment.timeSlot),
                  trailing: Chip(
                    label: Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(
                        color: appointment.statusColor,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: appointment.statusColor.withOpacity(0.1),
                  ),
                  onTap: () {
                    // Navigate to appointment detail
                    Navigator.pushNamed(context, '/doctor/appointments');
                  },
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildRecentPatients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Patients', style: AppStyles.heading2),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all patients
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, color: AppColors.textLight),
                ),
                title: Text('Patient ${index + 1}'),
                subtitle: const Text('Last Visit: Yesterday'),
                trailing: IconButton(
                  icon: const Icon(Icons.medical_services),
                  onPressed: () {
                    // TODO: View medical history
                  },
                ),
                onTap: () {
                  // TODO: Navigate to patient details
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
