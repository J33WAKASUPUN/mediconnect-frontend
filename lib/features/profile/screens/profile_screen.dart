import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/user_model.dart';
import 'package:mediconnect/core/utils/datetime_helper.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart'; // Add this import
import 'package:mediconnect/features/profile/widgets/doctor_profile_section.dart';
import 'package:mediconnect/features/profile/widgets/patient_profile_section.dart'
    as patient_profile;
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/profile_image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final bool hideAppBar;
  final bool readOnly;

  const ProfileScreen({
    super.key,
    this.hideAppBar = false,
    this.readOnly = false, required Map<String, dynamic> userData,
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

    final calendarProvider =
        Provider.of<CalendarProvider>(context, listen: false);

    // Check if we need to load calendar data
    if (calendarProvider.calendar == null) {
      _calendarLoading = true;

      // Get date range for current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      print('Pre-loading calendar data for doctor: ${user.id}');

      // Load calendar data
      calendarProvider
          .fetchCalendar(
        doctorId: user.id,
        startDate: startDate,
        endDate: endDate,
        forceRefresh: true,
      )
          .then((_) {
        if (mounted) setState(() => _calendarLoading = false);
        print('Calendar pre-load complete');
      }).catchError((e) {
        if (mounted) setState(() => _calendarLoading = false);
        print('Error pre-loading calendar: $e');
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
    final now = DateTime.now().toUtc();
    final formattedDateTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    // Try to preload calendar data when we have a user
    if (user != null && user.role == 'doctor') {
      // Trigger calendar data loading if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_calendarLoading) {
          _preloadCalendarData(user);
        }
      });
    }

    return LoadingOverlay(
      isLoading: profileProvider.isLoading,
      child: Scaffold(
        appBar: widget.hideAppBar
            ? null
            : AppBar(
                title: const Text('Profile'),
                actions: [
                  if (!widget.readOnly)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // Refresh profile
                        profileProvider.getProfile();

                        // Also refresh calendar if doctor
                        if (user != null && user.role == 'doctor') {
                          final calendarProvider =
                              Provider.of<CalendarProvider>(context,
                                  listen: false);
                          calendarProvider.resetState(); // Reset state first
                          _preloadCalendarData(user); // Reload calendar data
                        }
                      },
                    ),
                ],
              ),
        body: profileProvider.error != null
            ? Center(
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
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Info Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): $formattedDateTime',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Current User\'s Login: J33WAKASUPUN',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (user != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: user.profilePicture != null
                                ? NetworkImage(user.profilePicture!)
                                : null,
                            backgroundColor: user.profilePicture == null
                                ? Theme.of(context).primaryColor
                                : null,
                            onBackgroundImageError: (exception, stackTrace) {
                              // Handle image load error silently
                              setState(() {});
                            },
                            child: user.profilePicture == null
                                ? Text(
                                    '${user.firstName[0]}${user.lastName[0]}'
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.firstName} ${user.lastName}',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  user.role.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Profile Sections
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Last Updated Info
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.update, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Last Updated: ${DateTimeHelper.formatDateTime(profileProvider.lastUpdated)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Basic Profile Section
                      BasicProfileSection(user: user),
                      const SizedBox(height: 24),

                      // Role-specific Additional Profile Section
                      if (user.role == 'patient')
                        patient_profile.PatientProfileSection(
                          profile: profileProvider.patientProfile,
                        )
                      else if (user.role == 'doctor')
                        // Small delay to ensure calendar is preloaded first
                        Builder(builder: (context) {
                          return DoctorProfileSection(
                            profile: profileProvider.doctorProfile,
                          );
                        }),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

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
    // Debug print to check if user data is available
    print(
        "BasicProfileSection initialized with user: ${widget.user?.toJson()}");
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: widget.user?.firstName);
    _lastNameController = TextEditingController(text: widget.user?.lastName);
    _phoneController = TextEditingController(text: widget.user?.phoneNumber);
    _addressController = TextEditingController(text: widget.user?.address);

    // Debug print to check controller values
    print(
        "Controllers initialized with: firstName=${_firstNameController.text}, lastName=${_lastNameController.text}, phone=${_phoneController.text}, address=${_addressController.text}");
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
    // Print debug info when building
    print(
        "Building BasicProfileSection with: firstName=${widget.user?.firstName}, lastName=${widget.user?.lastName}");

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Profile Image Section
              if (_isEditing)
                ProfileImagePicker(
                  currentImageUrl: widget.user?.profilePicture,
                  selectedImage: _selectedImage,
                  onImageSelected: (file) {
                    setState(() => _selectedImage = file);
                  },
                )
              else
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.user?.profilePicture != null
                        ? NetworkImage(widget.user!.profilePicture!)
                        : null,
                    backgroundColor: widget.user?.profilePicture == null
                        ? Theme.of(context).primaryColor
                        : null,
                    child: widget.user?.profilePicture == null &&
                            widget.user != null
                        ? Text(
                            '${widget.user!.firstName[0]}${widget.user!.lastName[0]}'
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: 24),

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
                // View Mode - Show non-editable information
                if (widget.user?.firstName != null)
                  _buildInfoRow('First Name', widget.user!.firstName),
                if (widget.user?.lastName != null)
                  _buildInfoRow('Last Name', widget.user!.lastName),
                if (widget.user?.email != null)
                  _buildInfoRow('Email', widget.user!.email),
                if (widget.user?.phoneNumber != null)
                  _buildInfoRow('Phone Number', widget.user!.phoneNumber),
                if (widget.user?.address != null)
                  _buildInfoRow('Address', widget.user!.address),
                if (widget.user == null ||
                    (widget.user?.firstName == null &&
                        widget.user?.lastName == null &&
                        widget.user?.phoneNumber == null &&
                        widget.user?.address == null))
                  const Text(
                    "No basic information available",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
              ],

              const SizedBox(height: 24),
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

  // Helper method for displaying info in rows with labels
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
