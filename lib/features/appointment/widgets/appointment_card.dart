import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    Key? key,
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
  }) : super(key: key);

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
              _buildInfoRow(Icons.calendar_today, appointment.formattedAppointmentDate),
              _buildInfoRow(Icons.access_time, appointment.timeSlot),
              
              if (!isCompact)
                _buildInfoRow(Icons.subject, appointment.reason),
              
              _buildInfoRow(
                Icons.payments, 
                'Rs. ${appointment.amount.toStringAsFixed(2)} ${appointment.paymentId != null ? "(Paid)" : ""}'
              ),

              // Action buttons
              if (!isCompact && _shouldShowActions()) ...[
                const SizedBox(height: 16),
                _buildActionButtons(),
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
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel button for pending/confirmed appointments
        if (onCancelPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: onCancelPressed,
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
          
        // Payment button
        if (onPaymentPressed != null)
          ElevatedButton(
            onPressed: onPaymentPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Pay Now'),
          ),
      ],
    );
  }
}