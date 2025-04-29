import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../appointment/providers/appointment_provider.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;
  
  const PatientDetailsScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  User? _patientData;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _patientAppointments = [];
  Map<String, dynamic>? _patientProfile;
  
  final ApiService _apiService = ApiService();
  
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
      // Fetch patient details
      final response = await _apiService.getUserById(widget.patientId);
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _patientData = User.fromJson(response['data']);
          _patientProfile = response['data']['patientProfile'];
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load patient data';
        });
      }
      
      // Get patient appointments
      final appointmentProvider = context.read<AppointmentProvider>();
      _patientAppointments = appointmentProvider.appointments
          .where((apt) => apt.patientId == widget.patientId)
          .toList();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_patientData != null 
            ? '${_patientData!.firstName} ${_patientData!.lastName}'
            : 'Patient Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
          ),
        ],
      ),
      body: _isLoading 
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadPatientData)
              : _buildPatientDetails(),
    );
  }
  
  Widget _buildPatientDetails() {
    if (_patientData == null) {
      return const Center(
        child: Text('No patient data available'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientBasicInfo(),
          const SizedBox(height: 24),
          _buildPatientMedicalInfo(),
          const SizedBox(height: 24),
          _buildPatientAppointmentHistory(),
        ],
      ),
    );
  }
  
  Widget _buildPatientBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  backgroundImage: _patientData?.profilePicture != null
                      ? NetworkImage(_patientData!.profilePicture!)
                      : null,
                  child: _patientData?.profilePicture == null
                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_patientData!.firstName} ${_patientData!.lastName}',
                        style: AppStyles.heading1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _patientData!.email,
                        style: AppStyles.bodyText2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _patientData!.phoneNumber,
                        style: AppStyles.bodyText2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Gender', _patientData!.gender),
            _buildInfoRow('Address', _patientData!.address),
            _buildInfoRow('Since', _formatDate(_patientData!.createdAt)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPatientMedicalInfo() {
    final hasProfileData = _patientProfile != null && _patientProfile!.isNotEmpty;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_information, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Medical Information', style: AppStyles.heading2),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!hasProfileData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No medical information available'),
                ),
              )
            else 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_patientProfile!['bloodType'] != null)
                    _buildInfoRow('Blood Type', _patientProfile!['bloodType']),
                    
                  if (_patientProfile!['allergies'] != null && 
                      (_patientProfile!['allergies'] as List).isNotEmpty)
                    _buildListInfoRow('Allergies', _patientProfile!['allergies']),
                    
                  if (_patientProfile!['currentMedications'] != null && 
                      (_patientProfile!['currentMedications'] as List).isNotEmpty)
                    _buildListInfoRow('Current Medications', _patientProfile!['currentMedications']),
                    
                  if (_patientProfile!['chronicConditions'] != null && 
                      (_patientProfile!['chronicConditions'] as List).isNotEmpty)
                    _buildListInfoRow('Chronic Conditions', _patientProfile!['chronicConditions']),
                    
                  if (_patientProfile!['medicalHistory'] != null && 
                      (_patientProfile!['medicalHistory'] as List).isNotEmpty)
                    _buildListInfoRow('Medical History', _patientProfile!['medicalHistory']),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPatientAppointmentHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Appointment History', style: AppStyles.heading2),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_patientAppointments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No appointment history available'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _patientAppointments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final appointment = _patientAppointments[index];
                  return ListTile(
                    title: Text(
                      'Date: ${_formatDate(appointment.appointmentDate)} (${appointment.timeSlot})',
                    ),
                    subtitle: Text(
                      'Reason: ${appointment.reason}\nStatus: ${appointment.status}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: appointment.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appointment.status.toUpperCase(),
                        style: TextStyle(
                          color: appointment.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListInfoRow(String label, List<dynamic> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((item) {
              return Chip(
                label: Text(item.toString()),
                backgroundColor: AppColors.primary.withOpacity(0.1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}