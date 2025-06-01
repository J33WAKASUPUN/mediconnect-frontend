import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/appointment/widgets/appointment_card.dart';
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

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    try {
      final appointmentProvider = context.read<AppointmentProvider>();
      
      debugPrint('Initializing DoctorAppointmentsScreen');
      
      await Future.wait([
        appointmentProvider.loadAppointments(),
        appointmentProvider.syncPaymentStatus(),
      ]);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing appointments: $e');
    }
  }

  Future<void> _refreshData() async {
    final appointmentProvider = context.read<AppointmentProvider>();
    await Future.wait([
      appointmentProvider.loadAppointments(),
      appointmentProvider.syncPaymentStatus(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, child) => _buildBody(provider),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: const Text(
        'My Appointments',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        tabs: const [
          Tab(
            text: 'Upcoming',
            icon: Icon(Icons.schedule, size: 20),
          ),
          Tab(
            text: 'Past',
            icon: Icon(Icons.history, size: 20),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _refreshData,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(AppointmentProvider provider) {
    debugPrint('Provider state: isLoading=${provider.isLoading}, error=${provider.error}');
    debugPrint('Upcoming appointments: ${provider.upcomingAppointments.length}');
    debugPrint('Past appointments: ${provider.pastAppointments.length}');

    if (provider.isLoading && !_isInitialized) {
      return const Center(child: LoadingIndicator());
    }

    if (provider.error != null) {
      return ErrorView(
        message: provider.error!,
        onRetry: _refreshData,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAppointmentsList(
          context,
          provider.upcomingAppointments,
          isUpcoming: true,
          isLoading: provider.isLoading,
        ),
        _buildAppointmentsList(
          context,
          provider.pastAppointments,
          isUpcoming: false,
          isLoading: provider.isLoading,
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    List<Appointment> appointments, {
    required bool isUpcoming,
    bool isLoading = false,
  }) {
    if (appointments.isEmpty && !isLoading) {
      return _buildEmptyState(isUpcoming);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primary,
      child: Stack(
        children: [
          ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildEnhancedAppointmentCard(appointment, isUpcoming);
            },
          ),
          if (isLoading)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Refreshing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUpcoming ? Icons.event_available : Icons.history,
                  size: 64,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isUpcoming ? 'No Upcoming Appointments' : 'No Past Appointments',
                style: AppStyles.heading2.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isUpcoming
                    ? 'Your upcoming patient appointments will appear here'
                    : 'Your completed appointments will appear here',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppointmentCard(Appointment appointment, bool isUpcoming) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAppointmentActions(context, appointment, isUpcoming),
        borderRadius: BorderRadius.circular(12),
        child: AppointmentCard(
          appointment: appointment,
          isPatientView: false,
          onTap: () => _showAppointmentActions(context, appointment, isUpcoming),
          onConfirmPressed: _canConfirmAppointment(appointment, isUpcoming)
              ? (reason) async {
                  await context
                      .read<AppointmentProvider>()
                      .confirmAppointment(appointment.id);
                }
              : null,
          onCancelPressed: _canCancelAppointment(appointment, isUpcoming)
              ? () => _showCancelConfirmation(context, appointment)
              : null,
          onCompletePressed: _canCompleteAppointment(appointment, isUpcoming)
              ? () => _completeAppointment(context, appointment.id)
              : null,
          onCreateMedicalRecord: _canCreateMedicalRecord(appointment, isUpcoming)
              ? () => _createMedicalRecord(context, appointment)
              : null,
          onViewMedicalRecord: _canViewMedicalRecord(appointment, isUpcoming)
              ? () => _navigateToMedicalRecord(context, appointment)
              : null,
          onViewPatientProfile: () => _showPatientProfile(context, appointment),
        ),
      ),
    );
  }

  // Helper methods for button visibility
  bool _canConfirmAppointment(Appointment appointment, bool isUpcoming) {
    return isUpcoming && appointment.status == 'pending';
  }

  bool _canCancelAppointment(Appointment appointment, bool isUpcoming) {
    return isUpcoming && 
           (appointment.status == 'pending' || appointment.status == 'confirmed');
  }

  bool _canCompleteAppointment(Appointment appointment, bool isUpcoming) {
    return isUpcoming && appointment.status == 'confirmed';
  }

  bool _canCreateMedicalRecord(Appointment appointment, bool isUpcoming) {
    return !isUpcoming && 
           appointment.status == 'completed' && 
           appointment.medicalRecord == null;
  }

  bool _canViewMedicalRecord(Appointment appointment, bool isUpcoming) {
    return !isUpcoming && 
           appointment.status == 'completed' && 
           appointment.medicalRecord != null;
  }

  void _showAppointmentActions(BuildContext context, Appointment appointment, bool isUpcoming) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionBottomSheet(appointment, isUpcoming),
    );
  }

  Widget _buildActionBottomSheet(Appointment appointment, bool isUpcoming) {
    final patientName = appointment.patientDetails != null
        ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
        : 'Patient';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Appointment Options',
                  style: AppStyles.heading2.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                // Confirm appointment button
                if (_canConfirmAppointment(appointment, isUpcoming))
                  _buildActionTile(
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    title: 'Confirm Appointment',
                    subtitle: 'Accept this appointment request',
                    onTap: () {
                      Navigator.pop(context);
                      _confirmAppointment(context, appointment.id);
                    },
                  ),

                // Complete appointment button
                if (_canCompleteAppointment(appointment, isUpcoming))
                  _buildActionTile(
                    icon: Icons.task_alt,
                    iconColor: AppColors.primary,
                    title: 'Mark as Completed',
                    subtitle: 'Finish this appointment',
                    onTap: () {
                      Navigator.pop(context);
                      _completeAppointment(context, appointment.id);
                    },
                  ),

                // Cancel button
                if (_canCancelAppointment(appointment, isUpcoming))
                  _buildActionTile(
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.error,
                    title: 'Cancel Appointment',
                    subtitle: 'This will notify the patient',
                    onTap: () {
                      Navigator.pop(context);
                      _showCancelConfirmation(context, appointment);
                    },
                  ),

                // Create medical record
                if (_canCreateMedicalRecord(appointment, isUpcoming))
                  _buildActionTile(
                    icon: Icons.note_add_outlined,
                    iconColor: AppColors.info,
                    title: 'Create Medical Record',
                    subtitle: 'Add diagnosis and prescriptions',
                    onTap: () {
                      Navigator.pop(context);
                      _createMedicalRecord(context, appointment);
                    },
                  ),

                // View medical record
                if (_canViewMedicalRecord(appointment, isUpcoming))
                  _buildActionTile(
                    icon: Icons.medical_information_outlined,
                    iconColor: AppColors.info,
                    title: 'View Medical Record',
                    subtitle: 'Check diagnosis and prescriptions',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMedicalRecord(context, appointment);
                    },
                  ),

                // View patient profile
                _buildActionTile(
                  icon: Icons.person_outline,
                  iconColor: AppColors.primary,
                  title: 'View Patient Profile',
                  subtitle: 'Check patient details and history',
                  onTap: () {
                    Navigator.pop(context);
                    _showPatientProfile(context, appointment);
                  },
                ),

                const SizedBox(height: 16),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _confirmAppointment(BuildContext context, String appointmentId) async {
    try {
      await context.read<AppointmentProvider>().confirmAppointment(appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm appointment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showCancelConfirmation(BuildContext context, Appointment appointment) async {
    final patientName = appointment.patientDetails != null
        ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
        : 'Patient';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DoctorAppointmentActionDialog(
        appointmentId: appointment.id,
        patientName: patientName,
        appointmentDate: appointment.appointmentDate,
        actionType: AppointmentAction.cancel,
      ),
    );

    if (result != null && result['confirmed'] == true && mounted) {
      try {
        final reason = result['reason'] ?? '';
        await context
            .read<AppointmentProvider>()
            .cancelAppointmentWithReason(appointment.id, reason);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeAppointment(BuildContext context, String appointmentId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Complete Appointment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Mark this appointment as completed? You can create a medical record afterwards.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await context.read<AppointmentProvider>().completeAppointment(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete appointment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
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
            try {
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medical record created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshData();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create medical record: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _navigateToMedicalRecord(BuildContext context, Appointment appointment) {
    if (appointment.medicalRecord != null) {
      final patientName = appointment.patientDetails != null
          ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
          : 'Patient';
      
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
  }

  void _showPatientProfile(BuildContext context, Appointment appointment) {
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
        const SnackBar(
          content: Text('Patient information not available'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}