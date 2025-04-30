import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancel Appointment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to cancel your appointment with ${widget.doctorName} on ${_formatDate(widget.appointmentDate)}?',
              style: TextStyle(fontSize: 16),
            ),

            // Show refund information if payment was made
            if (widget.hasPaidPayment) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payments, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Refund Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will receive a full refund for this appointment. The refund will be processed to your original payment method and may take 3-5 business days to appear in your account.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              'Please select a reason for cancellation:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Predefined reasons
            if (!_customReason) ...[
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
            ] else ...[
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Please specify your reason',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close),
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
            ],

            const SizedBox(height: 24),

            Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: provider.isCancelling
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text('Keep Appointment'),
                    ),
                    const SizedBox(width: 16),
                    provider.isCancelling
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => _confirmCancellation(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Cancel Appointment'),
                          ),
                  ],
                );
              },
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
        SnackBar(content: Text('Please provide a reason for cancellation')),
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
      if (result is Map && result.containsKey('success')) {
        final bool success = result['success'] == true;
        final String message = result['message'] ?? 'Appointment cancelled successfully';
        final bool hasRefundInfo = message.contains('Refund');

        if (success && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Text('Appointment Cancelled')
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your appointment has been successfully cancelled.'),
                  SizedBox(height: 16),
                  if (hasRefundInfo) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payments, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Refund Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(message.replaceAll(
                              'Appointment cancelled successfully.', '')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Handle unexpected result type
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unexpected response format. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
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
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}