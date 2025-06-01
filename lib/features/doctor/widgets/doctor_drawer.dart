import 'package:flutter/material.dart';
import 'package:mediconnect/core/utils/session_helper.dart';
import 'package:mediconnect/features/doctor/screens/doctor_dashboard.dart';
import 'package:mediconnect/features/messages/provider/message_provider.dart';
import 'package:mediconnect/features/notification/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/styled_drawer_item.dart';

class DoctorDrawer extends StatefulWidget {
  const DoctorDrawer({super.key});

  @override
  State<DoctorDrawer> createState() => _DoctorDrawerState();
}

class _DoctorDrawerState extends State<DoctorDrawer> {
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
    final userLogin = SessionHelper.getUserLogin();
    final screenWidth = MediaQuery.of(context).size.width;

    final drawerWidth = screenWidth * 0.7;

    return Container(
      width: drawerWidth, // Set custom width
      child: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Stylized Header - match the screenshot style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 30),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Picture with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!)
                          : null,
                      child: user?.profilePicture == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username with Dr. prefix
                  Text(
                    'Dr. ${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable menu items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    StyledDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(
                            context, '/doctor/dashboard');
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.calendar_today,
                      title: 'My Appointments',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/doctor/appointments');
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.people,
                      title: 'My Patients',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/doctor/patients');
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.schedule,
                      title: 'Schedule',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/doctor/calendar');
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.calendar_month,
                      title: 'Calendar Management',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                            context, '/doctor/calendar/working-hours');
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.person,
                      title: 'Profile',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        final dashboardState = context
                            .findAncestorStateOfType<DoctorDashboardState>();
                        if (dashboardState != null) {
                          dashboardState.changeTab(2);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: AppColors.divider, thickness: 1),
                    ),
                    const SizedBox(height: 8),
                    StyledDrawerItem(
                      icon: Icons.message,
                      title: 'Messages',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      trailing: Consumer<MessageProvider>(
                        builder: (context, provider, _) {
                          try {
                            final unreadCount = provider.totalUnreadCount;
                            if (unreadCount > 0) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            // Silently handle any errors
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/messages');
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      trailing: Consumer<NotificationProvider>(
                        builder: (context, provider, _) {
                          if (provider.unreadCount > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                provider.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/notifications')
                            .then((_) {
                          if (mounted) {
                            context
                                .read<NotificationProvider>()
                                .loadNotifications();
                          }
                        });
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.health_and_safety,
                      title: 'Health Assistant',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/health-assistant');
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to settings
                      },
                    ),
                    StyledDrawerItem(
                      icon: Icons.help,
                      title: 'Help & Support',
                      backgroundColor: const Color(0xFFF0F0FF),
                      textColor: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to help
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section with logout and version
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logout button
                StyledDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  backgroundColor:
                      const Color(0xFFFFEBEE), // Light red background
                  textColor: Colors.red,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await context.read<AuthProvider>().logout();
                    navigator.pushReplacementNamed('/login');
                  },
                ),

                // Version text (small and centered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 4),
                  child: Text(
                    'MediConnect v2.5.0',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
