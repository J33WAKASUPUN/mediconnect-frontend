import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/appointment/widgets/appointment_cancellation_dialog.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import 'appointment_status_badge.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isPatientView;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onCancelPressed;
  final VoidCallback? onConfirmPressed;
  final VoidCallback? onCompletePressed;
  final VoidCallback? onReviewPressed;
  final VoidCallback? onViewMedicalRecord;
  final VoidCallback? onCreateMedicalRecord;
  final VoidCallback? onPaymentPressed;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isPatientView = true,
    this.isCompact = false,
    this.onTap,
    this.onCancelPressed,
    this.onConfirmPressed,
    this.onCompletePressed,
    this.onReviewPressed,
    this.onViewMedicalRecord,
    this.onCreateMedicalRecord,
    this.onPaymentPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get the name depending on view
    final String name;
    if (isPatientView) {
      name = appointment.doctorDetails != null
          ? 'Dr. ${appointment.doctorDetails!['firstName']} ${appointment.doctorDetails!['lastName']}'
          : 'Doctor';
    } else {
      name = appointment.patientDetails != null
          ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
          : 'Patient';
    }

    // Get specialty/info
    final String subtitle = isPatientView
        ? appointment.doctorDetails?['doctorProfile']?['specialization'] ?? ''
        : appointment.reason;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: appointment.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppStyles.subtitle1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: AppStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppointmentStatusBadge(status: appointment.status),
                ],
              ),

              if (!isCompact) const Divider(height: 24),

              // Appointment details
              _buildInfoRow(
                  Icons.calendar_today, appointment.formattedAppointmentDate),
              _buildInfoRow(Icons.access_time, appointment.timeSlot),

              if (!isCompact) _buildInfoRow(Icons.subject, appointment.reason),

              if (appointment.cancelledBy != null &&
                  appointment.cancelledBy!.isNotEmpty)
                _buildInfoRow(Icons.cancel,
                    'Cancelled by: ${appointment.cancelledBy == 'patient' ? 'You' : 'Doctor'}'),

              if (appointment.cancellationReason != null &&
                  appointment.cancellationReason!.isNotEmpty)
                _buildInfoRow(Icons.info_outline,
                    'Reason: ${appointment.cancellationReason}'),

              _buildInfoRow(Icons.payments,
                  'Rs. ${appointment.amount.toStringAsFixed(2)} ${appointment.paymentId != null ? "(Paid)" : ""}'),

              // Action buttons
              if (!isCompact && _shouldShowActions()) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context), // Pass context here
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowActions() {
    // Check if there are any actions to show
    return onCancelPressed != null ||
        onConfirmPressed != null ||
        onCompletePressed != null ||
        onReviewPressed != null ||
        onViewMedicalRecord != null ||
        onCreateMedicalRecord != null ||
        onPaymentPressed != null;
  }

  bool _isPaymentNeeded(BuildContext context) {
    // Get appointment provider
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);

    // First, check if the appointment has a payment ID directly
    if (appointment.paymentId != null) {
      return false;
    }

    // Next, check if it's in our paid appointments list
    if (appointmentProvider.isAppointmentPaid(appointment.id)) {
      return false;
    }

    // Only show payment button for pending appointments without payment
    return (appointment.status.toLowerCase() == 'pending_payment' ||
        appointment.status.toLowerCase() == 'pending');
  }

  void _showCancellationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AppointmentCancellationDialog(
        appointmentId: appointment.id,
        doctorName: appointment.doctorDetails != null
            ? 'Dr. ${appointment.doctorDetails!['firstName']} ${appointment.doctorDetails!['lastName']}'
            : 'Doctor',
        appointmentDate: appointment.appointmentDate,
        hasPaidPayment: appointment.paymentId != null ||
            Provider.of<AppointmentProvider>(context, listen: false)
                .isAppointmentPaid(appointment.id),
      ),
    ).then((result) {
      // Handle result from dialog if needed
      if (result != null &&
          result is Map<String, dynamic> &&
          result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);

    print("Appointment ID: ${appointment.id}");
    print("Payment ID: ${appointment.paymentId}");
    print("Status: ${appointment.status}");
    print("Is Payment Needed: ${_isPaymentNeeded(context)}");
    print(
        "Is payment completed: ${appointmentProvider.isAppointmentPaid(appointment.id)}");
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel button for pending/confirmed appointments
        if (onCancelPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () => _showCancellationDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Cancel'),
            ),
          ),

        // Confirm button for doctor (pending appointments)
        if (onConfirmPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: onConfirmPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Confirm'),
            ),
          ),

        // Complete button for doctor (confirmed appointments)
        if (onCompletePressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: onCompletePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Complete'),
            ),
          ),

        // Review button for patient (completed appointments)
        if (onReviewPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: onReviewPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
              ),
              child: const Text('Review'),
            ),
          ),

        // Medical record buttons
        if (onViewMedicalRecord != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: onViewMedicalRecord,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
              ),
              child: const Text('Medical Record'),
            ),
          ),

        if (onCreateMedicalRecord != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: onCreateMedicalRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
              ),
              child: const Text('Create Record'),
            ),
          ),

        // Payment button - Show different states based on payment status
        if (_isPaymentNeeded(context) && onPaymentPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('Pay Now'),
              onPressed: onPaymentPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // Show PAID button if payment is completed
        if ((appointment.paymentId != null ||
            appointmentProvider.isAppointmentPaid(appointment.id)))
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Payment Completed'),
              onPressed: null, // Disabled button
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.green,
                disabledForegroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
