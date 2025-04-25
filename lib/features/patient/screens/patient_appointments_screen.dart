import 'package:flutter/material.dart';
import 'package:mediconnect/core/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/medical_record_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../appointment/providers/appointment_provider.dart';
import '../../appointment/widgets/appointment_card.dart';
import '../../appointment/widgets/review_dialog.dart';
import '../../payment/screens/payment_screen.dart';
import '../../medical_records/screens/medical_record_detail_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  _PatientAppointmentsScreenState createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    print("Initializing PatientAppointmentsScreen");
    // Use a more direct approach to load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Loading appointments...");
      // Print current user info
      final user = context.read<AuthProvider>().user;
      print("Current user: ${user?.id}, ${user?.role}");

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
            print(
                "Provider state: isLoading=${provider.isLoading}, error=${provider.error}");
            print(
                "Upcoming appointments: ${provider.upcomingAppointments.length}");
            print("Past appointments: ${provider.pastAppointments.length}");

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

            return TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(
                  context,
                  provider.upcomingAppointments,
                  true,
                ),
                _buildAppointmentsList(
                  context,
                  provider.pastAppointments,
                  false,
                ),
              ],
            );
          },
        ));
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    List<Appointment> appointments,
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
              isUpcoming ? 'No upcoming appointments' : 'No past appointments',
              style: AppStyles.heading2,
            ),
            const SizedBox(height: 8),
            if (isUpcoming)
              CustomButton(
                text: 'Find a Doctor',
                onPressed: () {
                  Navigator.pushNamed(context, '/patient/doctors');
                },
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
            isPatientView: true,
            onTap: () {
              // View appointment details
              // This could navigate to a detailed screen
            },
            onCancelPressed: isUpcoming && appointment.status == 'pending' ||
                    appointment.status == 'confirmed'
                ? () => _showCancelConfirmation(context, appointment.id)
                : null,
            onReviewPressed: !isUpcoming &&
                    appointment.status == 'completed' &&
                    appointment.review == null
                ? () => _showReviewDialog(context, appointment)
                : null,
            onViewMedicalRecord: !isUpcoming &&
                    appointment.status == 'completed' &&
                    appointment.medicalRecord != null
                ? () => _navigateToMedicalRecord(context, appointment)
                : null,
            onPaymentPressed: isUpcoming &&
                    appointment.status == 'confirmed' &&
                    appointment.paymentId == null
                ? () => _navigateToPayment(context, appointment)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _showCancelConfirmation(
      BuildContext context, String appointmentId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
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
          .cancelAppointment(appointmentId);
    }
  }

  void _showReviewDialog(BuildContext context, Appointment appointment) {
    final doctorName = appointment.doctorDetails != null
        ? 'Dr. ${appointment.doctorDetails!['firstName']} ${appointment.doctorDetails!['lastName']}'
        : 'your doctor';

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        doctorName: doctorName,
        onSubmit: (rating, comment) async {
          await context.read<AppointmentProvider>().addReview(
                appointment.id,
                rating,
                comment,
              );
        },
      ),
    );
  }

  void _navigateToMedicalRecord(BuildContext context, Appointment appointment) {
    if (appointment.medicalRecord != null) {
      // Create a MedicalRecord from the appointment's medicalRecord map
      final record = MedicalRecord.fromJson(appointment.medicalRecord!);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicalRecordDetailScreen(
            record: record,
          ),
        ),
      );
    }
  }

  void _navigateToPayment(BuildContext context, Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          appointment: appointment,
        ),
      ),
    );
  }
}
