import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/review_model.dart';
import 'package:mediconnect/core/services/api_service.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/medical_records/screens/medical_record_detail_screen.dart';
import 'package:mediconnect/features/patient/screens/medical_records_screen.dart';
import 'package:mediconnect/features/review/providers/review_provider.dart';
import 'package:mediconnect/features/review/widgets/review_card.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/constants/colors.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  
  const PatientProfileScreen({
    super.key,
    required this.patientId,
  });

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _patientData;
  List _appointments = [];
  bool _loadingRecords = false;
  List<dynamic> _patientRecords = [];
  List<dynamic> _patientReviews = [];
  bool _loadingReviews = false;
  
  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }
  
  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Get appointment provider to fetch appointments
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      final patientAppointments = appointmentProvider.appointments
          .where((apt) => apt.patientId == widget.patientId)
          .toList();
      
      // Store appointments
      _appointments = patientAppointments;
      
      // Extract basic patient info from appointments
      Map<String, dynamic> basicPatientData = {};
      if (patientAppointments.isNotEmpty && patientAppointments[0].patientDetails != null) {
        basicPatientData = patientAppointments[0].patientDetails!;
        print('Found basic patient data: $basicPatientData');
      } else {
        print('No patient details in appointments');
      }
      
      // Set the basic patient data we found
      setState(() {
        _patientData = basicPatientData;
        _isLoading = false;
      });

      // Load patient medical records
      _loadPatientRecords();
      
      // Load patient reviews
      _loadPatientReviews();
      
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPatientRecords() async {
    if (mounted) {
      setState(() {
        _loadingRecords = true;
      });
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/medical-records/patient/${widget.patientId}');
      
      if (response['success'] && response['data'] != null) {
        List<dynamic> records = [];
        
        // Handle different response structures
        if (response['data'] is List) {
          records = response['data'];
        } else if (response['data']['records'] != null) {
          records = response['data']['records'];
        } else if (response['data']['medicalRecords'] != null) {
          records = response['data']['medicalRecords'];
        }
        
        // Update the state
        if (mounted) {
          setState(() {
            _patientRecords = records;
            _loadingRecords = false;
          });
        }
      }
    } catch (e) {
      print('Error loading patient records: $e');
      if (mounted) {
        setState(() {
          _loadingRecords = false;
        });
      }
    }
  }
  
  Future<void> _loadPatientReviews() async {
    if (mounted) {
      setState(() {
        _loadingReviews = true;
      });
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Try getting all reviews by this patient directly (if endpoint exists)
      try {
        final response = await apiService.get('/reviews/patient/${widget.patientId}');
        
        if (response['success'] && response['data'] != null) {
          List<dynamic> reviews = [];
          
          // Handle different response formats
          if (response['data'] is List) {
            reviews = response['data'];
          } else if (response['data']['reviews'] != null) {
            reviews = response['data']['reviews'];
          } else {
            // Single review case
            reviews.add(response['data']);
          }
          
          if (mounted) {
            setState(() {
              _patientReviews = reviews;
              _loadingReviews = false;
            });
            return; // Exit early since we got the reviews
          }
        }
      } catch (e) {
        print('Patient reviews endpoint not available: $e');
        // Continue with fallback approach
      }
      
      // Fallback: fetch reviews appointment by appointment
      List<dynamic> allReviews = [];
      
      // Check completed appointments for this patient
      final completedAppointments = _appointments.where((apt) => 
        apt.status.toLowerCase() == 'completed' && apt.doctorId.isNotEmpty).toList();
      
      print('Found ${completedAppointments.length} completed appointments');
      
      // For each completed appointment, check if there's a review
      for (var appointment in completedAppointments) {
        try {
          // Find reviews by appointment ID
          print('Checking for reviews on appointment: ${appointment.id}');
          final response = await apiService.get('/reviews/appointment/${appointment.id}');
          
          if (response['success'] && response['data'] != null) {
            print('Found review data for appointment ${appointment.id}');
            
            if (response['data'] is List) {
              allReviews.addAll(response['data']);
            } else {
              allReviews.add(response['data']);
            }
          }
        } catch (e) {
          print('Error fetching review for appointment ${appointment.id}: $e');
        }
      }
      
      // Debug output
      print('Total reviews found: ${allReviews.length}');
      
      if (mounted) {
        setState(() {
          _patientReviews = allReviews;
          _loadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading patient reviews: $e');
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    }
  }

  void _showAllMedicalRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientMedicalRecordsScreen(
          patientId: widget.patientId,
          patientName: "${_patientData!['firstName'] ?? ''} ${_patientData!['lastName'] ?? ''}",
        ),
      ),
    );
  }
  
  Future<void> _handleDoctorResponse(String reviewId, String response) async {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true; 
    });
    
    try {
      final success = await reviewProvider.addDoctorResponse(
        reviewId: reviewId,
        response: response,
      );
      
      if (success) {
        // Refresh reviews
        _loadPatientReviews();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Response added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reviewProvider.error ?? 'Failed to add response'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding doctor response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDebugButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.bug_report, size: 16),
        label: const Text('Debug Reviews'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          try {
            // Test if review data is present
            print('Debug: Patient reviews data:');
            print('Reviews count: ${_patientReviews.length}');
            
            if (_patientReviews.isNotEmpty) {
              print('First review: ${_patientReviews[0]}');
              
              // Try parsing the review
              final review = Review.fromJson(_patientReviews[0]);
              print('Review ID: ${review.id}');
              print('Review by patient: ${review.patientId}');
              print('Review for doctor: ${review.doctorId}');
              print('Review content: ${review.review}');
            }
            
            // Check completed appointments
            final completedAppointments = _appointments
                .where((apt) => apt.status.toLowerCase() == 'completed')
                .toList();
            
            print('Completed appointments: ${completedAppointments.length}');
            
            // Try manually fetching a review for an appointment
            if (completedAppointments.isNotEmpty) {
              final apiService = Provider.of<ApiService>(context, listen: false);
              final firstCompletedAppointment = completedAppointments[0];
              print('Checking appointment ID: ${firstCompletedAppointment.id}');
              
              try {
                final response = await apiService.get(
                    '/reviews/appointment/${firstCompletedAppointment.id}');
                print('API response: $response');
              } catch (e) {
                print('API error: $e');
              }
            }
            
            // Show success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Debug info printed to console'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } catch (e) {
            print('Debug error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Debug error: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Patient Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: LoadingIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Patient Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Unknown error',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadPatientData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_patientData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Patient Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: Text('Patient data not available')),
      );
    }

    final patientName = "${_patientData!['firstName'] ?? ''} ${_patientData!['lastName'] ?? ''}";
    final profileImage = _patientData!['profilePicture'];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Patient Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPatientData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with patient info
          Container(
            color: AppColors.primary,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                        child: profileImage == null
                            ? Text(
                                _getInitials(
                                  _patientData!['firstName']?.toString() ?? '', 
                                  _patientData!['lastName']?.toString() ?? ''
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_patientData!.containsKey('email') && _patientData!['email'] != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.email,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _patientData!['email'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (_patientData!.containsKey('phoneNumber') && _patientData!['phoneNumber'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _patientData!['phoneNumber'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
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
                // Statistics row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Appointments',
                        _appointments.length.toString(),
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Medical Records',
                        _patientRecords.length.toString(),
                        Icons.medical_services,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Reviews Given',
                        _patientReviews.length.toString(),
                        Icons.star,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  // Basic Patient Info
                  if (_hasContactInfo())
                    _buildSection(
                      'Contact Information',
                      Icons.contact_page,
                      Colors.blue,
                      Column(
                        children: _buildContactInfoFields(),
                      ),
                    ),
                    
                  // Patient Reviews Section
                  _buildSection(
                    'Patient Reviews',
                    Icons.star_rate,
                    Colors.orange,
                    Column(
                      children: [
                        if (_loadingReviews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (_patientReviews.isEmpty)
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.star_border,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No reviews from this patient yet',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Debug button only shown during development
                              _buildDebugButton(),
                            ],
                          )
                        else
                          ...List.generate(_patientReviews.length, (index) {
                            try {
                              final reviewJson = _patientReviews[index];
                              final review = Review.fromJson(reviewJson);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ReviewCard(
                                  review: review,
                                  isDoctorView: true,
                                  onResponseSubmit: (response) {
                                    _handleDoctorResponse(review.id, response);
                                  },
                                ),
                              );
                            } catch (e) {
                              print('Error rendering review card #$index: $e');
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text('Error displaying review: $e'),
                              );
                            }
                          }),
                      ],
                    ),
                  ),
                    
                  // Medical Records Summary Section
                  _buildSection(
                    'Medical Records',
                    Icons.medical_information,
                    Colors.green,
                    Column(
                      children: [
                        if (_loadingRecords)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (_patientRecords.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.medical_information_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No medical records found',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              ...List.generate(
                                _patientRecords.length > 3 ? 3 : _patientRecords.length,
                                (index) {
                                  final record = _patientRecords[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MedicalRecordDetailScreen(
                                                recordId: record['_id'],
                                                isDoctorView: true,
                                                patientName: patientName,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.medical_services,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      record['diagnosis'] ?? 'Medical Record',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Dr. ${record['doctorId']?['firstName'] ?? ''} ${record['doctorId']?['lastName'] ?? ''}',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                                },
                              ),
                              if (_patientRecords.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text('Show All Records'),
                                    onPressed: _showAllMedicalRecords,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green,
                                      side: BorderSide(color: Colors.green.shade300),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    showViewAll: _patientRecords.isNotEmpty,
                    onViewAll: _showAllMedicalRecords,
                  ),
                    
                  // Appointment history
                  _buildSection(
                    'Appointment History',
                    Icons.history,
                    AppColors.primary,
                    Column(
                      children: [
                        if (_appointments.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No appointment history available',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...List.generate(_appointments.length, (index) {
                            final appointment = _appointments[index];
                            final status = appointment.status.toLowerCase();
                            final isCompleted = status == 'completed';
                            final isCancelled = status == 'cancelled';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: appointment.statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                _getStatusIcon(status),
                                                size: 16,
                                                color: appointment.statusColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _formatDate(appointment.appointmentDate),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: appointment.statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: appointment.statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAppointmentInfoRow(Icons.access_time, 'Time', appointment.timeSlot),
                                    const SizedBox(height: 8),
                                    _buildAppointmentInfoRow(Icons.subject, 'Reason', appointment.reason),

                                    if (isCompleted && appointment.medicalRecord != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.medical_services,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'Medical record available',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final String recordId = appointment.medicalRecord!['_id'];
                                                Navigator.push(
                                                  context, 
                                                  MaterialPageRoute(
                                                    builder: (context) => MedicalRecordDetailScreen(
                                                      recordId: recordId,  
                                                      isDoctorView: true,
                                                      patientName: "${_patientData!['firstName'] ?? ''} ${_patientData!['lastName'] ?? ''}",
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              ),
                                              child: const Text(
                                                'View Record',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    if (isCancelled && appointment.cancellationReason != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.red.shade700,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Cancellation reason: ${appointment.cancellationReason}',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // Session info at bottom
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted):',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Text(
                            "2025-06-01 21:26:49",
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current User\'s Login:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Text(
                            "J33WAKASUPUN",
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Monospace',
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color iconColor,
    Widget content, {
    bool showViewAll = false,
    VoidCallback? onViewAll,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showViewAll) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      foregroundColor: iconColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'confirmed':
        return Icons.event_available;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.event;
    }
  }

  bool _hasContactInfo() {
    return (_patientData!.containsKey('email') && _patientData!['email'] != null) ||
           (_patientData!.containsKey('phoneNumber') && _patientData!['phoneNumber'] != null) ||
           (_patientData!.containsKey('gender') && _patientData!['gender'] != null) ||
           (_patientData!.containsKey('address') && _patientData!['address'] != null);
  }

  List<Widget> _buildContactInfoFields() {
    List<Widget> fields = [];
    
    if (_patientData!.containsKey('gender') && _patientData!['gender'] != null) {
      fields.add(_buildInfoRow('Gender', _patientData!['gender']));
    }
      
    if (_patientData!.containsKey('address') && _patientData!['address'] != null) {
      fields.add(_buildInfoRow('Address', _patientData!['address']));
    }
      
    return fields;
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
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