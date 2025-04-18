import 'package:flutter/material.dart';
import 'package:mediconnect/core/utils/session_helper.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_bottom_navigation.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/patient_provider.dart';
import '../widgets/patient_drawer.dart';
import '../../profile/screens/profile_screen.dart';

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
    const Center(child: Text('Appointments')), // Placeholder
    const ProfileScreen(),
  ];

  final currentTime = SessionHelper.getCurrentUTC();
  final userLogin = SessionHelper.getUserLogin();

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() => context.read<PatientProvider>().getPatientProfile());
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
        ),
        drawer: const PatientDrawer(),
        body: _screens[_currentIndex],
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
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

    return RefreshIndicator(
      onRefresh: () => patientProvider.getPatientProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, user?.firstName ?? ''),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildHealthSummary(),
            const SizedBox(height: 24),
            _buildUpcomingAppointments(),
            const SizedBox(height: 24),
            _buildRecentMedicalRecords(),
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
              'Welcome, $name',
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

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(
          icon: Icons.calendar_today,
          title: 'Book\nAppointment',
          color: AppColors.primary,
          onTap: () {
            // TODO: Navigate to book appointment
          },
        ),
        _buildActionCard(
          icon: Icons.medical_services,
          title: 'Medical\nRecords',
          color: AppColors.secondary,
          onTap: () {
            // TODO: Navigate to medical records
          },
        ),
        _buildActionCard(
          icon: Icons.notifications,
          title: 'Medication\nReminders',
          color: AppColors.warning,
          onTap: () {
            // TODO: Navigate to reminders
          },
        ),
        _buildActionCard(
          icon: Icons.message,
          title: 'Contact\nDoctor',
          color: AppColors.info,
          onTap: () {
            // TODO: Navigate to messages
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Summary', style: AppStyles.heading2),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHealthInfoRow(
                  icon: Icons.bloodtype,
                  label: 'Blood Type',
                  value: 'A+',
                ),
                const Divider(),
                _buildHealthInfoRow(
                  icon: Icons.monitor_weight,
                  label: 'Weight',
                  value: '70 kg',
                ),
                const Divider(),
                _buildHealthInfoRow(
                  icon: Icons.height,
                  label: 'Height',
                  value: '175 cm',
                ),
                const Divider(),
                _buildHealthInfoRow(
                  icon: Icons.medical_services,
                  label: 'Last Checkup',
                  value: '2025-02-15',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: AppStyles.bodyText1),
          ),
          Text(
            value,
            style: AppStyles.bodyText1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Appointments', style: AppStyles.heading2),
            CustomButton(
              text: 'Book New',
              onPressed: () {
                // TODO: Navigate to book appointment
              },
              icon: Icons.add,
              isSecondary: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                ),
                title: Text('Dr. Smith ${index + 1}'),
                subtitle: Text(
                  'March ${12 + index}, 2025 - ${9 + index}:00 AM',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Confirmed',
                    style: TextStyle(color: AppColors.success),
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to appointment details
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMedicalRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Medical Records', style: AppStyles.heading2),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all medical records
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
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  child: const Icon(
                    Icons.folder_open,
                    color: AppColors.secondary,
                  ),
                ),
                title: Text('General Checkup ${index + 1}'),
                subtitle: Text(
                  'Dr. Johnson - March ${5 - index}, 2025',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to record details
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Current session info
        Card(
          color: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Session',
                  style: AppStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Time (UTC): 2025-03-11 17:21:21',
                      style: AppStyles.bodyText2,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'User ID: J33WAKASUPUN',
                      style: AppStyles.bodyText2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
