import 'package:flutter/material.dart';
import 'package:mediconnect/core/utils/session_helper.dart';
import 'package:mediconnect/features/patient/screens/patient_dashboard.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class PatientDrawer extends StatelessWidget {
  const PatientDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currentTime = SessionHelper.getCurrentUTC();
    final userLogin = SessionHelper.getUserLogin();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.surface,
              backgroundImage: user?.profilePicture != null
                  ? NetworkImage(user!.profilePicture!)
                  : null,
              child: user?.profilePicture == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 35)
                  : null,
            ),
            accountName: Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              style: AppStyles.heading2.copyWith(
                color: AppColors.textLight,
              ),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email ?? '',
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  'ID: $userLogin',
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.textLight.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                        context, '/patient/dashboard');
                  },
                ),
                const Divider(),
                // Add Your Doctors option
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Your Doctors'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/patient/doctors');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('My Appointments'),
                  onTap: () {
                    Navigator.pop(context);
                    final dashboardState =
                        context.findAncestorStateOfType<PatientDashboardState>();
                    if (dashboardState != null) {
                      dashboardState.changeTab(1);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Medical Records'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to medical records
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: const Text('Medications'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to medications
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    final dashboardState =
                        context.findAncestorStateOfType<PatientDashboardState>();
                    if (dashboardState != null) {
                      dashboardState.changeTab(2);
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to notifications
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Messages'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to messages
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments),
                  title: const Text('Billing & Payments'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to billing
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to help
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await context.read<AuthProvider>().logout();
                    navigator.pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentTime,
                      style: AppStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'MediConnect v1.0.0',
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}