import 'package:flutter/material.dart';
import 'package:mediconnect/features/review/screens/review_form_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../shared/constants/colors.dart';
import '../../doctor/widgets/doctor_appointment_action_dialog.dart';
import '../providers/appointment_provider.dart';
import 'appointment_cancellation_dialog.dart';
import 'appointment_status_badge.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isPatientView;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onCancelPressed;
  final Function(String)? onConfirmPressed;
  final VoidCallback? onCompletePressed;
  final VoidCallback? onReviewPressed;
  final VoidCallback? onViewMedicalRecord;
  final VoidCallback? onCreateMedicalRecord;
  final VoidCallback? onPaymentPressed;
  final VoidCallback? onViewPatientProfile;
  final String? paymentStatus;

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
    this.onViewPatientProfile,
    this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
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

    final String subtitle = isPatientView
        ? appointment.doctorDetails?['doctorProfile']?['specialization'] ?? ''
        : appointment.reason;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: const Color(0xFF6366F1).withOpacity(0.1),
          highlightColor: const Color(0xFF6366F1).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header Section
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPatientView ? Icons.medical_services_rounded : Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isPatientView && onViewPatientProfile != null)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: Color(0xFF6366F1),
                          ),
                          tooltip: 'View Patient Profile',
                          onPressed: onViewPatientProfile,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Enhanced Status Section
                Row(
                  children: [
                    AppointmentStatusBadge(status: appointment.status),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPaymentStatusColor(context).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPaymentStatusIcon(),
                            size: 14,
                            color: _getPaymentStatusColor(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getPaymentStatusText(context),
                            style: TextStyle(
                              color: _getPaymentStatusColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Enhanced Details Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF8FAFC),
                        const Color(0xFFF1F5F9).withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildModernInfoRow(
                        Icons.calendar_today_rounded,
                        'Date',
                        appointment.formattedAppointmentDate,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoRow(
                        Icons.access_time_rounded,
                        'Time',
                        appointment.timeSlot,
                        const Color(0xFF3B82F6),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 16),
                        _buildModernInfoRow(
                          Icons.subject_rounded,
                          'Reason',
                          appointment.reason,
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildModernInfoRow(
                        Icons.payments_rounded,
                        'Amount',
                        _getAmountText(context),
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),

                // Enhanced Cancellation Info
                if (appointment.cancelledBy != null && appointment.cancelledBy!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFEF2F2),
                          const Color(0xFFFEE2E2).withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      children: [
                        _buildModernInfoRow(
                          Icons.cancel_rounded,
                          'Cancelled by',
                          getCancelledByText(appointment, isPatientView),
                          const Color(0xFFEF4444),
                        ),
                        if (appointment.cancellationReason != null &&
                            appointment.cancellationReason!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildModernInfoRow(
                            Icons.info_outline_rounded,
                            'Reason',
                            appointment.cancellationReason!,
                            const Color(0xFFEF4444),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Enhanced Medical Record Indicator
                if (!isCompact &&
                    appointment.status.toLowerCase() == 'completed' &&
                    appointment.medicalRecord != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF0FDF4),
                          const Color(0xFFDCFCE7).withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medical_information_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Medical record available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Enhanced Action Buttons
                if (!isCompact && _shouldShowActions()) ...[
                  const SizedBox(height: 24),
                  _buildModernActionButtons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildModernActionButtons(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        // Modern Cancel Button
        if (onCancelPressed != null)
          _buildModernButton(
            icon: Icons.cancel_outlined,
            label: 'Cancel',
            onPressed: isPatientView
                ? () => _showCancellationDialog(context)
                : () => _showDoctorCancellationDialog(context),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFEF4444),
            borderColor: const Color(0xFFEF4444),
            isOutlined: true,
          ),

        // Modern Confirm Button
        if (onConfirmPressed != null)
          _buildModernButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Confirm',
            onPressed: () => _showDoctorConfirmationDialog(context),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),

        // Modern Complete Button
        if (onCompletePressed != null)
          _buildModernButton(
            icon: Icons.check_circle_rounded,
            label: 'Complete',
            onPressed: onCompletePressed,
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),

        // Modern Review Button
        if (onReviewPressed != null)
          _buildModernButton(
            icon: Icons.star_outline_rounded,
            label: 'Review',
            onPressed: () => _showReviewDialog(context),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFF59E0B),
            borderColor: const Color(0xFFF59E0B),
            isOutlined: true,
          ),

        // Modern Medical Record Buttons
        if (onViewMedicalRecord != null)
          _buildModernButton(
            icon: Icons.medical_information_outlined,
            label: 'View Record',
            onPressed: onViewMedicalRecord,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3B82F6),
            borderColor: const Color(0xFF3B82F6),
            isOutlined: true,
          ),

        if (onCreateMedicalRecord != null)
          _buildModernButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Create Record',
            onPressed: onCreateMedicalRecord,
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),

        // Modern Payment Button
        if (_isPaymentNeeded(context) && onPaymentPressed != null)
          _buildModernButton(
            icon: Icons.payment_rounded,
            label: 'Pay Now',
            onPressed: onPaymentPressed,
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),

        // Modern Paid Status
        // if ((appointment.paymentId != null || appointmentProvider.isAppointmentPaid(appointment.id)))
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //     decoration: BoxDecoration(
        //       gradient: LinearGradient(
        //         colors: [
        //           const Color(0xFF10B981).withOpacity(0.1),
        //           const Color(0xFF059669).withOpacity(0.05),
        //         ],
        //       ),
        //       borderRadius: BorderRadius.circular(12),
        //       border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        //     ),
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         Container(
        //           padding: const EdgeInsets.all(4),
        //           decoration: BoxDecoration(
        //             color: const Color(0xFF10B981),
        //             borderRadius: BorderRadius.circular(6),
        //           ),
        //           child: const Icon(
        //             Icons.check_rounded,
        //             size: 12,
        //             color: Colors.white,
        //           ),
        //         ),
        //         const SizedBox(width: 8),
        //         const Text(
        //           'Paid',
        //           style: TextStyle(
        //             color: Color(0xFF065F46),
        //             fontWeight: FontWeight.w600,
        //             fontSize: 14,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    bool isOutlined = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: !isOutlined
            ? [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : backgroundColor,
          foregroundColor: foregroundColor,
          side: isOutlined ? BorderSide(color: borderColor ?? foregroundColor, width: 1.5) : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isOutlined ? 0 : 2,
        ),
      ),
    );
  }

  IconData _getPaymentStatusIcon() {
    final paymentStatus = _getPaymentStatusText(null);
    switch (paymentStatus) {
      case 'PAID':
        return Icons.check_circle_rounded;
      case 'REFUNDED':
        return Icons.refresh_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  // Keep all existing methods unchanged
  String getCancelledByText(Appointment appointment, bool isPatientView) {
    if (appointment.cancelledBy == null) {
      return '';
    }

    if (isPatientView) {
      if (appointment.cancelledBy == 'patient') {
        return 'You';
      } else if (appointment.cancelledBy == 'doctor') {
        return 'Doctor';
      }
    } else {
      if (appointment.cancelledBy == 'patient') {
        return 'Patient';
      } else if (appointment.cancelledBy == 'doctor') {
        return 'You';
      }
    }

    return appointment.cancelledBy!;
  }

  String _getAmountText(BuildContext context) {
    String amountText = 'USD ${appointment.amount.toStringAsFixed(2)}';

    if (_getPaymentStatusText(context) == 'PAID') {
      amountText += ' (Paid)';
    } else if (_getPaymentStatusText(context) == 'REFUNDED') {
      amountText += ' (Refunded)';
    }

    return amountText;
  }

  String _getPaymentStatusText(BuildContext? context) {
    if (context == null) return 'UNPAID';
    
    final appProvider = Provider.of<AppointmentProvider>(context, listen: false);

    if (appointment.status.toLowerCase() == 'cancelled' && appointment.paymentId != null) {
      return 'REFUNDED';
    }

    if (appointment.status.toLowerCase() == 'cancelled' && appProvider.isAppointmentRefunded(appointment.id)) {
      return 'REFUNDED';
    }

    if (appointment.paymentId != null || appProvider.isAppointmentPaid(appointment.id)) {
      return 'PAID';
    }

    return 'UNPAID';
  }

  Color _getPaymentStatusColor(BuildContext context) {
    final appProvider = Provider.of<AppointmentProvider>(context, listen: false);

    if (appointment.status.toLowerCase() == 'cancelled' && appointment.paymentId != null) {
      return const Color(0xFF8B5CF6);
    }

    if (appointment.status.toLowerCase() == 'cancelled' && appProvider.isAppointmentRefunded(appointment.id)) {
      return const Color(0xFF8B5CF6);
    }

    if (appointment.paymentId != null || appProvider.isAppointmentPaid(appointment.id)) {
      return const Color(0xFF10B981);
    }

    return const Color(0xFFF59E0B);
  }

  bool _shouldShowActions() {
    return onCancelPressed != null ||
        onConfirmPressed != null ||
        onCompletePressed != null ||
        onReviewPressed != null ||
        onViewMedicalRecord != null ||
        onCreateMedicalRecord != null ||
        onPaymentPressed != null;
  }

  bool _isPaymentNeeded(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);

    if (appointment.paymentId != null) {
      return false;
    }

    if (appointmentProvider.isAppointmentPaid(appointment.id)) {
      return false;
    }

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
            Provider.of<AppointmentProvider>(context, listen: false).isAppointmentPaid(appointment.id),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic> && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _showDoctorConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => DoctorAppointmentActionDialog(
        appointmentId: appointment.id,
        patientName: appointment.patientDetails != null
            ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
            : 'Patient',
        appointmentDate: appointment.appointmentDate,
        actionType: AppointmentAction.confirm,
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic> && result['confirmed'] == true) {
        onConfirmPressed?.call(result['reason'] ?? '');
      }
    });
  }

  void _showDoctorCancellationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => DoctorAppointmentActionDialog(
        appointmentId: appointment.id,
        patientName: appointment.patientDetails != null
            ? '${appointment.patientDetails!['firstName']} ${appointment.patientDetails!['lastName']}'
            : 'Patient',
        appointmentDate: appointment.appointmentDate,
        actionType: AppointmentAction.cancel,
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic> && result['confirmed'] == true) {
        final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
        appointmentProvider.cancelAppointmentWithReason(appointment.id, result['reason'] ?? '');
      }
    });
  }

  void _showReviewDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewFormScreen(
          appointmentId: appointment.id,
          doctorId: appointment.doctorId,
          doctorName: appointment.doctorDetails != null
              ? 'Dr. ${appointment.doctorDetails!['firstName']} ${appointment.doctorDetails!['lastName']}'
              : 'Doctor',
          appointmentDate: appointment.formattedAppointmentDate,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thank you for your review!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }
}