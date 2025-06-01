import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/core/models/user_model.dart';
import 'package:mediconnect/core/utils/datetime_helper.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/features/profile/widgets/doctor_profile_section.dart';
import 'package:mediconnect/features/profile/widgets/patient_profile_section.dart' as patient_profile;
import 'package:mediconnect/shared/widgets/custom_textfield.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/profile_image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final bool hideAppBar;
  final bool readOnly;

  const ProfileScreen({
    super.key,
    this.hideAppBar = false,
    this.readOnly = false,
    required Map<String, dynamic> userData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _calendarLoading = false;

  @override
  void initState() {
    super.initState();
    // Load profile data when screen initializes (only if not readOnly)
    if (!widget.readOnly) {
      Future.microtask(() {
        context.read<ProfileProvider>().getProfile();
      });
    }
  }

  // Pre-load calendar data for doctor users
  void _preloadCalendarData(User user) {
    if (user.role != 'doctor' || _calendarLoading) return;

    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);

    // Check if we need to load calendar data
    if (calendarProvider.calendar == null) {
      _calendarLoading = true;

      // Get date range for current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      // Load calendar data
      calendarProvider.fetchCalendar(
        doctorId: user.id,
        startDate: startDate,
        endDate: endDate,
        forceRefresh: true,
      ).then((_) {
        if (mounted) setState(() => _calendarLoading = false);
      }).catchError((e) {
        if (mounted) setState(() => _calendarLoading = false);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we're showing a doctor profile
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null && user.role == 'doctor') {
      _preloadCalendarData(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final user = authProvider.user;

    // Try to preload calendar data when we have a user
    if (user != null && user.role == 'doctor') {
      // Trigger calendar data loading if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_calendarLoading) {
          _preloadCalendarData(user);
        }
      });
    }

    // Content to display based on loading/error state
    Widget buildContent() {
      if (profileProvider.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${profileProvider.error}'),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Retry',
                onPressed: () => profileProvider.getProfile(),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              // Basic Profile Section - now contains all user info
              BasicProfileSection(user: user),
              const SizedBox(height: 24),

              // Role-specific Additional Profile Section
              if (user.role == 'patient')
                patient_profile.PatientProfileSection(
                  profile: profileProvider.patientProfile,
                )
              else if (user.role == 'doctor')
                Builder(builder: (context) {
                  return DoctorProfileSection(
                    profile: profileProvider.doctorProfile,
                  );
                }),
            ],
          ],
        ),
      );
    }

    // Use the AppScaffold for consistent layout
    return LoadingOverlay(
      isLoading: profileProvider.isLoading,
      child: widget.hideAppBar
          ? Scaffold(
              body: buildContent(),
            )
          : AppScaffold(
              title: 'Profile',
              actions: [
                if (!widget.readOnly)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      // Refresh profile
                      profileProvider.getProfile();
                  
                      // Also refresh calendar if doctor
                      if (user != null && user.role == 'doctor') {
                        final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
                        calendarProvider.resetState();
                        _preloadCalendarData(user);
                      }
                    },
                  ),
              ],
              body: buildContent(),
            ),
    );
  }
}

// Enhanced BasicProfileSection with improved styling and all user info
class BasicProfileSection extends StatefulWidget {
  final User? user;

  const BasicProfileSection({
    super.key,
    required this.user,
  });

  @override
  State<BasicProfileSection> createState() => _BasicProfileSectionState();
}

class _BasicProfileSectionState extends State<BasicProfileSection> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  File? _selectedImage;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: widget.user?.firstName);
    _lastNameController = TextEditingController(text: widget.user?.lastName);
    _phoneController = TextEditingController(text: widget.user?.phoneNumber);
    _addressController = TextEditingController(text: widget.user?.address);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<ProfileProvider>().updateBasicProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        profilePicture: _selectedImage,
      );

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with profile image and name
              Center(
                child: Column(
                  children: [
                    // Profile Image
                    if (_isEditing)
                      ProfileImagePicker(
                        currentImageUrl: widget.user?.profilePicture,
                        selectedImage: _selectedImage,
                        onImageSelected: (file) {
                          setState(() => _selectedImage = file);
                        },
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: widget.user?.profilePicture != null
                              ? NetworkImage(widget.user!.profilePicture!)
                              : null,
                          backgroundColor: widget.user?.profilePicture == null
                              ? AppColors.primary
                              : null,
                          child: widget.user?.profilePicture == null && widget.user != null
                              ? Text(
                                  '${widget.user!.firstName[0]}${widget.user!.lastName[0]}'.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // User Name
                    Text(
                      widget.user?.role == 'doctor'
                        ? 'Dr. ${widget.user?.firstName ?? ''} ${widget.user?.lastName ?? ''}'
                        : '${widget.user?.firstName ?? ''} ${widget.user?.lastName ?? ''}',
                      style: AppStyles.heading2.copyWith(
                        color: AppColors.primary,
                        fontSize: 24,
                      ),
                    ),
                    
                    // Role Badge
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.user?.role.toUpperCase() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    
                    // Last Updated Subtle Text - only shown when not editing
                    if (!_isEditing && profileProvider.lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Last Updated: ${profileProvider.lastUpdated != null ? 
                              DateTimeHelper.formatDateTime(profileProvider.lastUpdated) : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const Divider(height: 36),

              // Section Header
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Basic Information',
                    style: AppStyles.heading3.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Personal Information Section
              if (_isEditing) ...[
                // Editing Mode - Show editable text fields
                CustomTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  enabled: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  enabled: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  enabled: true,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  enabled: true,
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
              ] else ...[
                // View Mode - Show styled non-editable information
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('First Name', widget.user?.firstName ?? 'Not specified', Icons.person_outline),
                      _buildInfoRow('Last Name', widget.user?.lastName ?? 'Not specified', Icons.person_outline),
                      _buildInfoRow('Email', widget.user?.email ?? 'Not specified', Icons.email_outlined),
                      _buildInfoRow('Phone Number', widget.user?.phoneNumber ?? 'Not specified', Icons.phone_outlined),
                      _buildInfoRow('Address', widget.user?.address ?? 'Not specified', Icons.location_on_outlined),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              
              // Edit/Save Button
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: _isEditing ? 'Save Changes' : 'Edit Profile',
                      onPressed: () {
                        if (_isEditing) {
                          _saveChanges();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                      icon: _isEditing ? Icons.save : Icons.edit,
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _initializeControllers();
                            _selectedImage = null;
                          });
                        },
                        isSecondary: true,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced helper method for displaying info rows with labels and icons
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}