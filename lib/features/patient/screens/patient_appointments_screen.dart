import 'package:flutter/material.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
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
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
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
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('Initializing PatientAppointmentsScreen');
      debugPrint('Current user: ${authProvider.user?.id}, ${authProvider.user?.role}');
      
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
                    ? 'Book your first appointment with our qualified doctors'
                    : 'Your completed appointments will appear here',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (isUpcoming) ...[
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Find a Doctor',
                  onPressed: () => Navigator.pushNamed(context, '/patient/doctors'),
                ),
              ],
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
          isPatientView: true,
          onTap: () => _showAppointmentActions(context, appointment, isUpcoming),
          onCancelPressed: _canCancelAppointment(appointment, isUpcoming)
              ? () => _showCancelConfirmation(context, appointment.id)
              : null,
          onReviewPressed: _canReviewAppointment(appointment, isUpcoming)
              ? () => _showReviewDialog(context, appointment)
              : null,
          onViewMedicalRecord: _canViewMedicalRecord(appointment, isUpcoming)
              ? () => _navigateToMedicalRecord(context, appointment)
              : null,
          onPaymentPressed: _isPaymentNeeded(appointment) && isUpcoming
              ? () => _navigateToPayment(context, appointment)
              : null,
        ),
      ),
    );
  }

  // Helper methods for button visibility
  bool _canCancelAppointment(Appointment appointment, bool isUpcoming) {
    return isUpcoming && 
           (appointment.status == 'pending' || appointment.status == 'confirmed');
  }

  bool _canReviewAppointment(Appointment appointment, bool isUpcoming) {
    return !isUpcoming && 
           appointment.status == 'completed' && 
           appointment.review == null;
  }

  bool _canViewMedicalRecord(Appointment appointment, bool isUpcoming) {
    return !isUpcoming && 
           appointment.status == 'completed' && 
           appointment.medicalRecord != null;
  }

  bool _isPaymentNeeded(Appointment appointment) {
    return appointment.status.toLowerCase() == 'pending_payment' ||
           (appointment.status.toLowerCase() == 'pending' && appointment.paymentId == null);
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

                // Payment button
                if (isUpcoming && _isPaymentNeeded(appointment))
                  _buildActionTile(
                    icon: Icons.payment,
                    iconColor: Colors.orange,
                    title: 'Make Payment',
                    subtitle: 'Rs. ${appointment.amount.toStringAsFixed(2)}',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPayment(context, appointment);
                    },
                  ),

                // Cancel button
                if (_canCancelAppointment(appointment, isUpcoming))
                  _buildActionTile(
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.error,
                    title: 'Cancel Appointment',
                    subtitle: 'This action cannot be undone',
                    onTap: () {
                      Navigator.pop(context);
                      _showCancelConfirmation(context, appointment.id);
                    },
                  ),

                // Review button
                if (_canReviewAppointment(appointment, isUpcoming))
                  _buildActionTile(
                    icon: Icons.star_outline,
                    iconColor: AppColors.warning,
                    title: 'Leave a Review',
                    subtitle: 'Share your experience',
                    onTap: () {
                      Navigator.pop(context);
                      _showReviewDialog(context, appointment);
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

  Future<void> _showCancelConfirmation(BuildContext context, String appointmentId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Appointment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to cancel this appointment? This action cannot be undone.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await context.read<AppointmentProvider>().cancelAppointment(appointmentId);
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

  void _showReviewDialog(BuildContext context, Appointment appointment) {
    final doctorName = appointment.doctorDetails != null
        ? 'Dr. ${appointment.doctorDetails!['firstName']} ${appointment.doctorDetails!['lastName']}'
        : 'your doctor';

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        doctorName: doctorName,
        onSubmit: (rating, comment) async {
          try {
            await context.read<AppointmentProvider>().addReview(
              appointment.id,
              rating,
              comment,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review submitted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit review: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _navigateToMedicalRecord(BuildContext context, Appointment appointment) {
    if (appointment.medicalRecord != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicalRecordDetailScreen(
            recordId: appointment.medicalRecord!['_id'],
            isDoctorView: false,
          ),
        ),
      );
    }
  }

  void _navigateToPayment(BuildContext context, Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(appointment: appointment),
      ),
    ).then((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }
}