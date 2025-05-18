import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/doctor/screens/patient_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../../../../../../core/models/appointment_model.dart';
import '../../../../../../../shared/constants/colors.dart';
import '../../../../../../../shared/constants/styles.dart';
import '../../../../../../../shared/widgets/loading_indicator.dart';
import '../../../../../../../shared/widgets/error_view.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AppointmentProvider>().loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search patients',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppointmentProvider>().loadAppointments();
            },
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: () {
                provider.loadAppointments();
              },
            );
          }

          // Get unique patients from appointments
          final Map<String, Map<String, dynamic>> uniquePatients = {};

          for (var appointment in provider.appointments) {
            if (appointment.patientDetails != null) {
              final patientId = appointment.patientId;
              final patientFirstName =
                  appointment.patientDetails!['firstName'] ?? '';
              final patientLastName =
                  appointment.patientDetails!['lastName'] ?? '';
              final fullName =
                  '$patientFirstName $patientLastName'.toLowerCase();

              // Add to unique patients if matches search query
              if (_searchQuery.isEmpty || fullName.contains(_searchQuery)) {
                uniquePatients[patientId] = {
                  'id': patientId,
                  'firstName': patientFirstName,
                  'lastName': patientLastName,
                  'appointment': appointment,
                  // Add more details as needed
                };
              }
            }
          }

          final patients = uniquePatients.values.toList();

          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 64,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No patients found'
                        : 'No patients match your search',
                    style: AppStyles.heading2,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final patient = patients[index];
              final appointment = patient['appointment'] as Appointment;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    patient['firstName'].substring(0, 1),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('${patient['firstName']} ${patient['lastName']}'),
                subtitle: Text(
                    'Last appointment: ${_formatDate(appointment.appointmentDate)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to patient details screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientProfileScreen(
                        patientId: patient['id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
