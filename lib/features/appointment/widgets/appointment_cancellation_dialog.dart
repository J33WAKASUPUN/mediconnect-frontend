import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../providers/appointment_provider.dart';

class AppointmentCancellationDialog extends StatefulWidget {
  final String appointmentId;
  final String doctorName;
  final DateTime appointmentDate;
  final bool hasPaidPayment;

  const AppointmentCancellationDialog({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.appointmentDate,
    required this.hasPaidPayment,
  });

  @override
  _AppointmentCancellationDialogState createState() =>
      _AppointmentCancellationDialogState();
}

class _AppointmentCancellationDialogState
    extends State<AppointmentCancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final List<String> _cancellationReasons = [
    'Schedule conflict',
    'No longer needed',
    'Found another doctor',
    'Health improved',
    'Other'
  ];

  String _selectedReason = 'Schedule conflict';
  bool _customReason = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Appointment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Appointment Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${widget.doctorName}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(widget.appointmentDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Show refund information if payment was made
                  if (widget.hasPaidPayment) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.payments,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Refund Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You will receive a full refund for this appointment. The refund will be processed to your original payment method and may take 3-5 business days to appear in your account.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    'Please select a reason for cancellation:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Predefined reasons
                  if (!_customReason) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedReason,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: _cancellationReasons.map((reason) {
                          return DropdownMenuItem(
                            value: reason,
                            child: Text(reason),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value!;
                            if (value == 'Other') {
                              _customReason = true;
                            }
                          });
                        },
                      ),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Please specify your reason',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _customReason = false;
                                _selectedReason = 'Schedule conflict';
                              });
                            },
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Consumer<AppointmentProvider>(
                    builder: (context, provider, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: provider.isCancelling
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Keep Appointment'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: provider.isCancelling
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.red,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Cancelling...',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _confirmCancellation(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Cancel Appointment'),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmCancellation(BuildContext context) async {
    // Get the reason
    final String reason =
        _customReason ? _reasonController.text.trim() : _selectedReason;

    // Validate
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide a reason for cancellation'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Get provider
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);

    try {
      // Process cancellation - passing reason as a String
      final result = await appointmentProvider.cancelAppointmentWithRefund(
        widget.appointmentId,
        reason, // This should be a String, not a Map
      );

      // Close current dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Check if result is a Map and contains the necessary keys
      if (result.containsKey('success')) {
        final bool success = result['success'] == true;
        final String message = result['message'] ?? 'Appointment cancelled successfully';
        final bool hasRefundInfo = message.contains('Refund');

        if (success && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Appointment Cancelled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Your appointment has been successfully cancelled.',
                            style: TextStyle(fontSize: 16),
                          ),
                          if (hasRefundInfo) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.payments,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Refund Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    message.replaceAll('Appointment cancelled successfully.', ''),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('OK'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Handle unexpected result type
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unexpected response format. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error cancelling appointment: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}