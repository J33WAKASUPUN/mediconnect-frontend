import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/constants/colors.dart';
import '../../appointment/providers/appointment_provider.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  
  const PatientProfileScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _patientData;
  List _appointments = [];
  
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
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Profile'),
        ),
        body: const Center(child: LoadingIndicator())
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Profile'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Unknown error', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPatientData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_patientData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Profile'),
        ),
        body: const Center(child: Text('Patient data not available')),
      );
    }

    final patientName = "${_patientData!['firstName'] ?? ''} ${_patientData!['lastName'] ?? ''}";
    final profileImage = _patientData!['profilePicture'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Patient header with name and image
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                    child: profileImage == null
                        ? Text(
                            _getInitials(
                              _patientData!['firstName']?.toString() ?? '', 
                              _patientData!['lastName']?.toString() ?? ''
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.blue,
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
                          patientName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_patientData!.containsKey('email') && _patientData!['email'] != null)
                          Text(
                            _patientData!['email'],
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        if (_patientData!.containsKey('phoneNumber') && _patientData!['phoneNumber'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _patientData!['phoneNumber'],
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Basic Patient Info
            if (_hasContactInfo())
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildContactInfoFields(),
                  ],
                ),
              ),
              
            // Appointment history
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_appointments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No appointment history available'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _appointments[index];
                        final status = appointment.status.toLowerCase();
                        final isCompleted = status == 'completed';
                        final isCancelled = status == 'cancelled';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Date: ${_formatDate(appointment.appointmentDate)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: appointment.statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: appointment.statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Time: ${appointment.timeSlot}'),
                                const SizedBox(height: 4),
                                Text('Reason: ${appointment.reason}'),

                                if (isCompleted && appointment.medicalRecord != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.medical_services, 
                                        size: 16, 
                                        color: Colors.green),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Medical record available',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Medical record viewing will be implemented soon'),
                                            ),
                                          );
                                        },
                                        child: const Text('View Record', style: TextStyle(color: Colors.blue)),
                                      ),
                                    ],
                                  ),
                                ],

                                if (isCancelled && appointment.cancellationReason != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cancellation reason: ${appointment.cancellationReason}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasContactInfo() {
    return (_patientData!.containsKey('email') && _patientData!['email'] != null) ||
           (_patientData!.containsKey('phoneNumber') && _patientData!['phoneNumber'] != null) ||
           (_patientData!.containsKey('gender') && _patientData!['gender'] != null) ||
           (_patientData!.containsKey('address') && _patientData!['address'] != null);
  }

  List<Widget> _buildContactInfoFields() {
    List<Widget> fields = [];
    
    if (_patientData!.containsKey('gender') && _patientData!['gender'] != null)
      fields.add(_buildInfoRow('Gender', _patientData!['gender']));
      
    if (_patientData!.containsKey('address') && _patientData!['address'] != null)
      fields.add(_buildInfoRow('Address', _patientData!['address']));
      
    return fields;
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
              label,
              style: const TextStyle(
                color: Colors.grey,
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
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _getInitials(String firstName, String lastName) {
    String firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }
}