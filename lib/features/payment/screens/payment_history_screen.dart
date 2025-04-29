import 'package:flutter/material.dart';
import 'package:mediconnect/features/payment/providers/payment_provider.dart';
import 'package:mediconnect/features/payment/screens/payment_details_screen.dart';
import 'package:mediconnect/features/payment/widgets/receipt_details_dialog.dart';
import 'package:mediconnect/shared/widgets/empty_state_view.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../core/models/payment_model.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    await Provider.of<PaymentProvider>(context, listen: false)
        .loadPaymentHistory(refresh: true);
  }

  Future<void> _loadMoreData() async {
    await Provider.of<PaymentProvider>(context, listen: false)
        .loadPaymentHistory(refresh: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<PaymentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.payments.isEmpty) {
              return const LoadingIndicator();
            }

            if (provider.error != null && provider.payments.isEmpty) {
              return ErrorView(
                message: provider.error!,
                onRetry: _loadData,
              );
            }

            if (provider.payments.isEmpty) {
              return const EmptyStateView(
                icon: Icons.payment,
                title: 'No Payment History',
                message: 'You haven\'t made any payments yet.',
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.payments.length +
                        (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.payments.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final payment = provider.payments[index];
                      return _buildPaymentCard(context, payment);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Update the _buildPaymentCard method in PaymentHistoryScreen
  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailsScreen(paymentId: payment.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.formattedDate,
                    style: AppStyles.bodyText2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _buildStatusChip(payment.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Appointment with ${payment.doctorName}',
                style: AppStyles.subtitle1,
              ),
              if (payment.appointmentDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Date: ${payment.appointmentDateFormatted}',
                  style: AppStyles.bodyText2,
                ),
              ],

              // Show refund details if refunded
              if (payment.isRefunded && payment.refundDetails != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.replay, color: Colors.purple, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Refund Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount: ${payment.currency} ${payment.refundDetails!['amount']}',
                            style: TextStyle(fontSize: 12),
                          ),
                          if (payment.refundDetails!['refundedAt'] != null)
                            Text(
                              'Date: ${_formatDate(DateTime.parse(payment.refundDetails!['refundedAt']))}',
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      if (payment.refundDetails!['reason'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reason: ${payment.refundDetails!['reason']}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.formattedAmount,
                    style: AppStyles.heading2.copyWith(
                      color:
                          payment.isRefunded ? Colors.grey : AppColors.primary,
                      decoration: payment.isRefunded
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    onPressed: payment.isSuccessful || payment.isRefunded
                        ? () => _viewReceiptDetails(context, payment.id)
                        : null,
                    color: (payment.isSuccessful || payment.isRefunded)
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    tooltip: 'View Receipt',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Add a helper method for date formatting
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'COMPLETED':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'PENDING':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'PROCESSING':
        color = Colors.blue;
        label = 'Processing';
        break;
      case 'FAILED':
        color = Colors.red;
        label = 'Failed';
        break;
      case 'REFUNDED':
        color = Colors.purple;
        label = 'Refunded';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    // Implement filter dialog for date range, status, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Payments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter options
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _viewReceiptDetails(BuildContext context, String paymentId) async {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Loading Receipt'),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            const Text('Please wait...'),
          ],
        ),
      ),
    );

    try {
      // Get receipt details
      final detailsResponse =
          await paymentProvider.getReceiptDetails(paymentId);

      // Close the loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (detailsResponse != null) {
        // Show receipt details dialog
        showDialog(
          context: context,
          builder: (BuildContext context) => ReceiptDetailsDialog(
            receiptData: detailsResponse['data'],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  paymentProvider.error ?? 'Failed to load receipt details')),
        );
      }
    } catch (e) {
      // Close the loading dialog if not already closed
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Error viewing receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing receipt: $e')),
      );
    }
  }
}
