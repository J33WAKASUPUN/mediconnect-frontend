import 'package:flutter/material.dart';
import 'package:mediconnect/features/payment/providers/payment_provider.dart';
import 'package:mediconnect/features/payment/screens/payment_details_screen.dart';
import 'package:mediconnect/features/payment/widgets/receipt_details_dialog.dart';
import 'package:mediconnect/shared/widgets/empty_state_view.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Payment History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            color: AppColors.primary,
            width: double.infinity,
            // padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     const Text(
            //       'Your Payment History',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 18,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     const SizedBox(height: 4),
            //     Text(
            //       'Track all your payments and receipts',
            //       style: TextStyle(
            //         color: Colors.white.withOpacity(0.8),
            //         fontSize: 14,
            //       ),
            //     ),
            //   ],
            // ),
          ),
          
          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
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
          
                  return ListView.builder(
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                // Header with date and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today, 
                            size: 12, 
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payment.formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(payment.status),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Doctor info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(
                        Icons.medical_services,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appointment with Dr. ${payment.doctorName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (payment.appointmentDate != null)
                            Text(
                              'Date: ${payment.appointmentDateFormatted}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Show refund details if refunded
                if (payment.isRefunded && payment.refundDetails != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
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
                            const SizedBox(width: 8),
                            const Text(
                              'Refund Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount: ${payment.currency} ${payment.refundDetails!['amount']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (payment.refundDetails!['refundedAt'] != null)
                              Text(
                                'Date: ${_formatDate(DateTime.parse(payment.refundDetails!['refundedAt']))}',
                                style: const TextStyle(fontSize: 13),
                              ),
                          ],
                        ),
                        if (payment.refundDetails!['reason'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${payment.refundDetails!['reason']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                
                // Footer with amount and receipt button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      payment.formattedAmount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: payment.isRefunded ? Colors.grey : AppColors.primary,
                        decoration: payment.isRefunded ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (payment.isSuccessful || payment.isRefunded)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.receipt, size: 16),
                        label: const Text('Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, 
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _viewReceiptDetails(context, payment.id),
                      ),
                  ],
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Filter Payments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date Range'),
              subtitle: const Text('All dates'),
              onTap: () {
                // Implement date range picker
              },
            ),
            
            // Status filter
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Payment Status'),
              subtitle: const Text('All statuses'),
              onTap: () {
                // Implement status filter
              },
            ),
            
            // Amount range filter
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Amount Range'),
              subtitle: const Text('All amounts'),
              onTap: () {
                // Implement amount range filter
              },
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 24),
              const Expanded(
                child: Text('Loading receipt details...'),
              ),
            ],
          ),
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
            content: Text(paymentProvider.error ?? 'Failed to load receipt details'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog if not already closed
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Error viewing receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error viewing receipt: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}