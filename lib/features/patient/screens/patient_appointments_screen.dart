// lib/features/patient/screens/patient_appointments_screen.dart

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

  Future<void> _loadAppointments() async {
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);
    await appointmentProvider.loadAppointments();
    await appointmentProvider.syncPaymentStatus(); // Sync payment status
  }
  Future<void> _refreshData() async {
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);
    await appointmentProvider.syncPaymentStatus();
  }

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

      _loadAppointments();
      _refreshData();
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

  // Helper method to check if payment is needed
  bool _isPaymentNeeded(Appointment appointment) {
    return appointment.status.toLowerCase() == 'pending_payment' ||
        (appointment.status.toLowerCase() == 'pending' &&
            appointment.paymentId == null);
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
              // Show appointment details or action sheet
              _showAppointmentActions(context, appointment, isUpcoming);
            },
            onCancelPressed: isUpcoming &&
                    (appointment.status == 'pending' ||
                        appointment.status == 'confirmed')
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
            onPaymentPressed: isUpcoming && _isPaymentNeeded(appointment)
                ? () => _navigateToPayment(context, appointment)
                : null,
          );
        },
      ),
    );
  }

  void _showAppointmentActions(
      BuildContext context, Appointment appointment, bool isUpcoming) {
    // Show bottom sheet with appointment actions
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Appointment Options',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 24),

              // Payment button
              if (isUpcoming && _isPaymentNeeded(appointment))
                ListTile(
                  leading: const Icon(Icons.payment, color: Colors.orange),
                  title: const Text('Make Payment'),
                  subtitle:
                      Text('Rs. ${appointment.amount.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToPayment(context, appointment);
                  },
                ),

              // Cancel button
              if (isUpcoming &&
                  (appointment.status == 'pending' ||
                      appointment.status == 'confirmed'))
                ListTile(
                  leading: const Icon(Icons.cancel, color: AppColors.error),
                  title: const Text('Cancel Appointment'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCancelConfirmation(context, appointment.id);
                  },
                ),

              // Review button
              if (!isUpcoming &&
                  appointment.status == 'completed' &&
                  appointment.review == null)
                ListTile(
                  leading: const Icon(Icons.star, color: AppColors.warning),
                  title: const Text('Leave a Review'),
                  onTap: () {
                    Navigator.pop(context);
                    _showReviewDialog(context, appointment);
                  },
                ),

              // View medical record
              if (!isUpcoming &&
                  appointment.status == 'completed' &&
                  appointment.medicalRecord != null)
                ListTile(
                  leading: const Icon(Icons.medical_information,
                      color: AppColors.info),
                  title: const Text('View Medical Record'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToMedicalRecord(context, appointment);
                  },
                ),

              const SizedBox(height: 8),

              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
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
    ).then((_) {
      // Refresh appointments after returning from payment screen
      if (mounted) {
        context.read<AppointmentProvider>().loadAppointments();
      }
    });
  }
}
