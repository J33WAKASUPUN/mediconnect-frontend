import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/features/payment/screens/payment_details_screen.dart';
import 'package:mediconnect/shared/widgets/empty_state_view.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/payment_provider.dart';
import '../../../core/models/payment_model.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
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
                    itemCount: provider.payments.length + (provider.isLoadingMore ? 1 : 0),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.formattedAmount,
                    style: AppStyles.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    onPressed: payment.isSuccessful
                        ? () => _downloadReceipt(context, payment.id)
                        : null,
                    color: payment.isSuccessful ? AppColors.primary : AppColors.textSecondary,
                    tooltip: 'Download Receipt',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  void _downloadReceipt(BuildContext context, String paymentId) async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading receipt...')),
    );
    
    final filePath = await provider.downloadReceipt(paymentId);
    
    if (filePath != null) {
      // Show success message with option to open the file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Receipt downloaded successfully'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Open the PDF file
              OpenFile.open(filePath);
            },
          ),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to download receipt')),
      );
    }
  }
}