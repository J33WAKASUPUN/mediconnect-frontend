import 'package:flutter/material.dart';
import 'package:mediconnect/features/doctor/widgets/medical_record_form.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../appointment/providers/appointment_provider.dart';
import '../../appointment/widgets/appointment_card.dart';
import '../widgets/medical_record_form.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  _DoctorAppointmentsScreenState createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      context.read<AppointmentProvider>().loadAppointments();
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
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
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

          final today = DateTime.now();
          
          final todayAppointments = provider.appointments
              .where((apt) => 
                apt.appointmentDate.year == today.year &&
                apt.appointmentDate.month == today.month &&
                apt.appointmentDate.day == today.day &&
                (apt.status == 'pending' || apt.status == 'confirmed'))
              .toList();
              
          final upcomingAppointments = provider.appointments
              .where((apt) => 
                apt.appointmentDate.isAfter(DateTime(today.year, today.month, today.day + 1)) &&
                (apt.status == 'pending' || apt.status == 'confirmed'))
              .toList();
              
          final pastAppointments = provider.appointments
              .where((apt) => 
                apt.status == 'completed' || 
                apt.status == 'cancelled' || 
                apt.status == 'no-show' ||
                apt.appointmentDate.isBefore(DateTime(today.year, today.month, today.day)))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentsList(context, todayAppointments, 'today\'s', true),
              _buildAppointmentsList(context, upcomingAppointments, 'upcoming', true),
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
              'No $type appointments',
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
          return AppointmentCard(
            appointment: appointment,
            isPatientView: false,
            onTap: () {
              // View appointment details
              // This could navigate to a detailed screen
            },
            onConfirmPressed: isUpcoming && appointment.status == 'pending'
                ? () => _confirmAppointment(context, appointment.id)
                : null,
            onCancelPressed: isUpcoming && 
                           (appointment.status == 'pending' || appointment.status == 'confirmed')
                ? () => _showCancelConfirmation(context, appointment.id)
                : null,
            onCompletePressed: isUpcoming && appointment.status == 'confirmed'
                ? () => _completeAppointment(context, appointment.id)
                : null,
            onCreateMedicalRecord: appointment.status == 'completed' && appointment.medicalRecord == null
                ? () => _createMedicalRecord(context, appointment)
                : null,
            onViewMedicalRecord: appointment.status == 'completed' && appointment.medicalRecord != null
                ? () => _viewMedicalRecord(context, appointment)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _confirmAppointment(BuildContext context, String appointmentId) async {
    await context.read<AppointmentProvider>().confirmAppointment(appointmentId);
  }

  Future<void> _showCancelConfirmation(BuildContext context, String appointmentId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
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
      await context.read<AppointmentProvider>().cancelAppointment(appointmentId);
    }
  }

  Future<void> _completeAppointment(BuildContext context, String appointmentId) async {
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
      await context.read<AppointmentProvider>().completeAppointment(appointmentId);
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
            final success = await context.read<AppointmentProvider>().createMedicalRecord(
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
    }
  }
}