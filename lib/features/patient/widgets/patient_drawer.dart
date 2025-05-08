import 'package:flutter/material.dart';
import 'package:mediconnect/core/utils/session_helper.dart';
import 'package:mediconnect/features/notification/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class PatientDrawer extends StatefulWidget {
  const PatientDrawer({super.key});

  @override
  State<PatientDrawer> createState() => _PatientDrawerState();
}

class _PatientDrawerState extends State<PatientDrawer> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<NotificationProvider>().loadNotifications();
      }
    });
  }

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
                    Navigator.pushNamed(context, '/patient/appointments');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Medical Records'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/medical-records');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: Consumer<NotificationProvider>(
                    builder: (context, provider, _) {
                      // Only show the badge if there are unread notifications
                      if (provider.unreadCount > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors
                                .error, // Change to red to make it stand out more
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.unreadCount.toString(),
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else {
                        // Return an empty widget when there are no unread notifications
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // When navigating to notifications, ensure we refresh when coming back
                    Navigator.pushNamed(context, '/notifications').then((_) {
                      // This runs when returning from notifications screen
                      if (mounted) {
                        context
                            .read<NotificationProvider>()
                            .loadNotifications();
                      }
                    });
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
                    Navigator.pushNamed(context, '/payment/history');
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
