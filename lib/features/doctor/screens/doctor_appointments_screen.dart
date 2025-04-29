import 'package:flutter/material.dart';
import 'package:mediconnect/features/doctor/widgets/doctor_appointment_action_dialog.dart';
import 'package:mediconnect/features/doctor/widgets/medical_record_form.dart';
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
                    await context
                        .read<AppointmentProvider>()
                        .cancelAppointment(appointment.id);
                  }
                : null,
            onCompletePressed: isUpcoming && appointment.status == 'confirmed'
                ? () => _completeAppointment(context, appointment.id)
                : null,
            onCreateMedicalRecord: appointment.status == 'completed' &&
                    appointment.medicalRecord == null
                ? () => _createMedicalRecord(context, appointment)
                : null,
            onViewMedicalRecord: appointment.status == 'completed' &&
                    appointment.medicalRecord != null
                ? () => _viewMedicalRecord(context, appointment)
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
    if (appointment.patientDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient details not available')),
      );
      return;
    }

    Navigator.pushNamed(context, '/doctor/patient-details',
        arguments: appointment.patientId);
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
