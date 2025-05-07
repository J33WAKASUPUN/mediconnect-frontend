import 'package:flutter/material.dart';
import 'package:mediconnect/features/doctor/screens/patient_profile_screen.dart';
import 'package:mediconnect/features/doctor/widgets/doctor_appointment_action_dialog.dart';
import 'package:mediconnect/features/doctor/widgets/medical_record_form.dart';
import 'package:mediconnect/features/medical_records/providers/medical_records_provider.dart';
import 'package:mediconnect/features/medical_records/screens/medical_record_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../appointment/providers/appointment_provider.dart';
import '../../appointment/widgets/appointment_card.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  _DoctorAppointmentsScreenState createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() {
      // Load appointments AND sync payment status
      final provider = context.read<AppointmentProvider>();
      provider.loadAppointments().then((_) {
        // Explicitly sync payment status after loading appointments
        provider.syncPaymentStatus();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'), // Removed 'Today' tab
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          // Add filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Statuses'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'confirmed',
                child: Text('Confirmed'),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Text('Cancelled'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
              const PopupMenuItem(
                value: 'no-show',
                child: Text('No-Show'),
              ),
            ],
          ),
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

          final today = DateTime.now();

          // Filter appointments by status if a filter is selected
          List<Appointment> filterAppointments(List<Appointment> appointments) {
            if (_statusFilter == 'all') return appointments;
            return appointments
                .where((apt) => apt.status == _statusFilter)
                .toList();
          }

          final upcomingAppointments = filterAppointments(
              provider.appointments.where((apt) => apt.isUpcoming).toList());

          final pastAppointments = filterAppointments(
              provider.appointments.where((apt) => apt.isPast).toList());

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentsList(
                  context, upcomingAppointments, 'upcoming', true),
              _buildAppointmentsList(context, pastAppointments, 'past', false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    List<Appointment> appointments,
    String type,
    bool isUpcoming,
  ) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _statusFilter != 'all'
                  ? 'No $_statusFilter appointments found'
                  : 'No $type appointments',
              style: AppStyles.heading2,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<AppointmentProvider>().loadAppointments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final patientName = appointment.patientDetails != null
              ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
              : 'Patient';

          return AppointmentCard(
            appointment: appointment,
            isPatientView: false,
            onTap: () {
              // View appointment details
            },
            onConfirmPressed: isUpcoming && appointment.status == 'pending'
                ? (reason) async {
                    await context
                        .read<AppointmentProvider>()
                        .confirmAppointment(appointment.id);
                  }
                : null,
            onCancelPressed: isUpcoming &&
                    (appointment.status == 'pending' ||
                        appointment.status == 'confirmed')
                ? () async {
                    // Show dialog to get cancellation reason
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => DoctorAppointmentActionDialog(
                        appointmentId: appointment.id,
                        patientName: patientName,
                        appointmentDate: appointment.appointmentDate,
                        actionType: AppointmentAction.cancel,
                      ),
                    );

                    if (result != null && result['confirmed'] == true) {
                      final reason = result['reason'] ?? '';
                      await context
                          .read<AppointmentProvider>()
                          .cancelAppointmentWithReason(appointment.id, reason);
                    }
                  }
                : null,
            onCompletePressed: isUpcoming && appointment.status == 'confirmed'
                ? () => _completeAppointment(context, appointment.id)
                : null,
            onCreateMedicalRecord: appointment.status == 'completed' &&
                    appointment.medicalRecord == null
                ? () {
                    // Navigate to the medical record form
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicalRecordForm(
                          appointmentId: appointment.id,
                          patientName: patientName,
                          onSubmit: (data) async {
                            // Call provider to create medical record
                            final success = await context
                                .read<MedicalRecordsProvider>()
                                .createMedicalRecord(
                                  appointmentId: appointment.id,
                                  diagnosis: data['diagnosis'],
                                  notes: data['notes'],
                                  prescriptions: data['prescriptions'],
                                  testResults: data['testResults'],
                                  nextVisitDate: data['nextVisitDate'] != null
                                      ? DateTime.parse(data['nextVisitDate'])
                                      : null,
                                );

                            if (success && context.mounted) {
                              // Navigate back to appointments screen
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Medical record created successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh appointments to show the new medical record
                              context
                                  .read<AppointmentProvider>()
                                  .loadAppointments();
                            }
                          },
                        ),
                      ),
                    );
                  }
                : null,
            onViewMedicalRecord: appointment.status == 'completed' &&
                    appointment.medicalRecord != null
                ? () {
                    // Navigate to medical record detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicalRecordDetailScreen(
                          recordId: appointment.medicalRecord!['_id'],
                          isDoctorView: true,
                          patientName: patientName,
                        ),
                      ),
                    );
                  }
                : null,
            // paymentStatus: appointment.paymentId != null ? 'paid' : 'unpaid',
            onViewPatientProfile: () =>
                _showPatientDetails(context, appointment),
          );
        },
      ),
    );
  }

  void _showPatientDetails(BuildContext context, Appointment appointment) {
    if (appointment.patientId.isNotEmpty &&
        appointment.patientDetails != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientProfileScreen(
            patientId: appointment.patientId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient information not available')),
      );
    }
  }

  Future<void> _completeAppointment(
      BuildContext context, String appointmentId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: const Text('Mark this appointment as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result == true) {
      await context
          .read<AppointmentProvider>()
          .completeAppointment(appointmentId);
    }
  }

  void _createMedicalRecord(BuildContext context, Appointment appointment) {
    final patientName = appointment.patientDetails != null
        ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
        : 'Patient';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalRecordForm(
          appointmentId: appointment.id,
          patientName: patientName,
          onSubmit: (data) async {
            final success =
                await context.read<AppointmentProvider>().createMedicalRecord(
                      appointment.id,
                      data,
                    );

            if (success) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _viewMedicalRecord(BuildContext context, Appointment appointment) {
    if (appointment.medicalRecord != null) {
      // Navigate to medical record detail screen
      // TODO: Implement medical record detail screen
    }
  }
}
