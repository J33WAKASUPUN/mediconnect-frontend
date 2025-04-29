import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/payment_model.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/payment_provider.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String paymentId;

  const PaymentDetailsScreen({
    super.key,
    required this.paymentId,
  });

  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    await Provider.of<PaymentProvider>(context, listen: false)
        .getPaymentDetails(widget.paymentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDetails) {
            return const LoadingIndicator();
          }

          if (provider.error != null) {
            return ErrorView(
              message: provider.error!,
              onRetry: _loadPaymentDetails,
            );
          }

          final payment = provider.selectedPayment;
          if (payment == null) {
            return const Center(
              child: Text('Payment not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(payment.status, payment.formattedAmount),
                const SizedBox(height: 24),

                // Payment Information
                _buildSection(
                  title: 'Payment Information',
                  children: [
                    _buildInfoRow('Payment ID', payment.id),
                    _buildInfoRow('Date', payment.formattedDate),
                    _buildInfoRow('Amount', payment.formattedAmount),
                    _buildInfoRow('Status', payment.statusText),
                    if (payment.paypalOrderId != null)
                      _buildInfoRow('PayPal Order ID', payment.paypalOrderId!),
                  ],
                ),

                const SizedBox(height: 24),

                // Appointment Information
                _buildSection(
                  title: 'Appointment Information',
                  children: [
                    _buildInfoRow('Doctor', payment.doctorName),
                    _buildInfoRow('Patient', payment.patientName),
                    if (payment.appointmentDate != null)
                      _buildInfoRow('Date', payment.appointmentDateFormatted),
                    if (payment.appointmentData != null &&
                        payment.appointmentData!['timeSlot'] != null)
                      _buildInfoRow(
                          'Time', payment.appointmentData!['timeSlot']),
                    if (payment.appointmentData != null &&
                        payment.appointmentData!['reason'] != null)
                      _buildInfoRow(
                          'Reason', payment.appointmentData!['reason']),
                  ],
                ),

                const SizedBox(height: 24),

                // Transaction Details (if available)
                if (payment.transactionDetails != null) ...[
                  _buildSection(
                    title: 'Transaction Details',
                    children: [
                      if (payment.transactionDetails!['captureId'] != null)
                        _buildInfoRow('Transaction ID',
                            payment.transactionDetails!['captureId']),
                      if (payment.transactionDetails!['paymentMethod'] != null)
                        _buildInfoRow('Payment Method',
                            payment.transactionDetails!['paymentMethod']),
                      if (payment.transactionDetails!['processorResponse'] !=
                              null &&
                          payment.transactionDetails!['processorResponse']
                                  ['message'] !=
                              null)
                        _buildInfoRow(
                            'Status Message',
                            payment.transactionDetails!['processorResponse']
                                ['message']),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Refund Details (if available)
                if (payment.isRefunded && payment.refundDetails != null) ...[
                  _buildSection(
                    title: 'Refund Information',
                    children: [
                      if (payment.refundDetails!['refundId'] != null)
                        _buildInfoRow(
                            'Refund ID', payment.refundDetails!['refundId']),
                      if (payment.refundDetails!['amount'] != null)
                        _buildInfoRow('Refund Amount',
                            '${payment.currency} ${payment.refundDetails!['amount']}'),
                      if (payment.refundDetails!['reason'] != null)
                        _buildInfoRow(
                            'Reason', payment.refundDetails!['reason']),
                      if (payment.refundDetails!['refundedAt'] != null)
                        _buildInfoRow(
                            'Date',
                            DateTime.parse(payment.refundDetails!['refundedAt'])
                                .toString()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions
                _buildActionButtons(payment),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(String status, String amount) {
    Color color;
    IconData icon;
    String message;

    switch (status) {
      case 'COMPLETED':
        color = Colors.green;
        icon = Icons.check_circle;
        message = 'Payment Successful';
        break;
      case 'PENDING':
        color = Colors.orange;
        icon = Icons.pending;
        message = 'Payment Pending';
        break;
      case 'PROCESSING':
        color = Colors.blue;
        icon = Icons.sync;
        message = 'Payment Processing';
        break;
      case 'FAILED':
        color = Colors.red;
        icon = Icons.error;
        message = 'Payment Failed';
        break;
      case 'REFUNDED':
        color = Colors.purple;
        icon = Icons.replay;
        message = 'Payment Refunded';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        message = 'Unknown Status';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: AppStyles.heading1,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyles.heading2,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.bodyText1.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyText1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Payment payment) {
    return Column(
      children: [
        if (payment.isSuccessful) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Download Receipt'),
              onPressed: () => _downloadReceipt(payment.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Cancel and Refund button (only for completed payments)
        if (payment.isSuccessful &&
            !payment.isRefunded &&
            payment.appointmentDate != null &&
            payment.appointmentDate!.isAfter(DateTime.now())) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel, color: AppColors.error),
              label: const Text('Cancel Appointment & Request Refund'),
              onPressed: () =>
                  _showRefundConfirmation(payment.id, payment.appointmentId),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _downloadReceipt(String paymentId) async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading receipt...')),
    );

    final filePath = await provider.downloadReceipt(paymentId);

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Receipt downloaded successfully'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              OpenFile.open(filePath);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to download receipt')),
      );
    }
  }

  void _showRefundConfirmation(String paymentId, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment & Request Refund'),
        content: const Text(
          'Are you sure you want to cancel this appointment and request a refund? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Appointment'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Yes, Request Refund'),
            onPressed: () {
              Navigator.pop(context);
              // Implement refund request
              _requestRefund(paymentId, appointmentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRefund(String paymentId, String appointmentId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Processing Refund'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                  child: Text(
                      'Please wait while we process your refund request...')),
            ],
          ),
        ),
      );

      // Get the appointment provider
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);

      // Process cancellation with refund
      final result = await appointmentProvider.cancelAppointmentWithRefund(
        appointmentId,
        'Cancelled by patient through payment details screen',
      );

      // Close loading dialog
      Navigator.pop(context);

      if (result['success']) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Refund Processed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                    'Your appointment has been cancelled and a refund has been initiated.'),
                SizedBox(height: 8),
                Text(
                  'The refund will be processed to your original payment method and may take 3-5 business days to appear in your account.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Close the dialog and go back to previous screen
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );

        // Refresh payment history
        Provider.of<PaymentProvider>(context, listen: false)
            .loadPaymentHistory(refresh: true);
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Refund Failed'),
            content: Text(result['message'] ??
                'Failed to process refund. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
