import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/doctor/screens/patient_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_overlay.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  
  String _selectedStatus = 'All';
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AppointmentProvider>().loadAppointments();
    });

    // Add listener to detect when text changes to show/hide X button
    _searchController.addListener(() {
      _onSearchChanged();

      // Update the state to show/hide X button
      if (_hasSearchText != (_searchController.text.isNotEmpty)) {
        setState(() {
          _hasSearchText = _searchController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Trigger rebuild to filter patients
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearchText = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredPatients(
      List<Appointment> appointments) {
    final Map<String, Map<String, dynamic>> uniquePatients = {};

    for (var appointment in appointments) {
      if (appointment.patientDetails != null) {
        final patientId = appointment.patientId;
        final patientFirstName = appointment.patientDetails!['firstName'] ?? '';
        final patientLastName = appointment.patientDetails!['lastName'] ?? '';
        final fullName = '$patientFirstName $patientLastName'.toLowerCase();
        
        // Filter by search query
        final matchesSearch = _searchController.text.isEmpty ||
            fullName.contains(_searchController.text.toLowerCase());
            
        // Filter by status
        final matchesStatus = _selectedStatus == 'All' ||
            appointment.status.toLowerCase() == _selectedStatus.toLowerCase();

        // Add to unique patients if matches filters
        if (matchesSearch && matchesStatus) {
          // Keep the most recent appointment for each patient
          if (!uniquePatients.containsKey(patientId) ||
              appointment.appointmentDate.isAfter(
                  uniquePatients[patientId]!['appointment'].appointmentDate)) {
            uniquePatients[patientId] = {
              'id': patientId,
              'firstName': patientFirstName,
              'lastName': patientLastName,
              'appointment': appointment,
              'email': appointment.patientDetails!['email'] ?? '',
              'phone': appointment.patientDetails!['phoneNumber'] ?? '',
              'profilePicture': appointment.patientDetails!['profilePicture'],
            };
          }
        }
      }
    }

    return uniquePatients.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search bar
                _buildSearchBar(),
                
                // Filter chips
                _buildStatusFilter(),
                
                // Patient counter
                Consumer<AppointmentProvider>(
                  builder: (context, provider, _) {
                    final patients = _getFilteredPatients(provider.appointments);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${patients.length} Patient${patients.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
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
          // Patient list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (provider.error != null) {
                  return SliverFillRemaining(
                    child: _buildErrorState(provider.error!),
                  );
                }

                final patients = _getFilteredPatients(provider.appointments);
                
                if (patients.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPatientCard(patients[index]),
                    childCount: patients.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My Patients',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.7),
                AppColors.primary,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => context.read<AppointmentProvider>().loadAppointments(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search icon with proper padding
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
            ),

            // Text field with proper constraints
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search patients by name',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 0,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
              ),
            ),

            // Clear button with proper padding
            if (_hasSearchText)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: _clearSearch,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final List<String> statuses = [
      'All',
      'pending',
      'confirmed',
      'cancelled',
      'completed'
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: statuses.map((status) {
            final isSelected = status == _selectedStatus;

            // Special styling for selected status
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: isSelected ? AppColors.primary : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final appointment = patient['appointment'] as Appointment;
    final profileImage = patient['profilePicture'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientProfileScreen(
                  patientId: patient['id'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Patient avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null
                        ? Text(
                            _getInitials(
                                patient['firstName'], patient['lastName']),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient['firstName']} ${patient['lastName']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (patient['email'].isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                patient['email'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last visit: ${_formatDate(appointment.appointmentDate)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appointment.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appointment.status.toUpperCase(),
                          style: TextStyle(
                            color: appointment.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No patients found'
                : 'No patients match your search',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Your patients will appear here once you have appointments'
                : 'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AppointmentProvider>().loadAppointments();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 80,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AppointmentProvider>().loadAppointments();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getInitials(String firstName, String lastName) {
    String firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }
}