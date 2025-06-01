import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/constants/colors.dart';

class ReceiptDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> receiptData;
  
  const ReceiptDetailsDialog({
    super.key, 
    required this.receiptData,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }
  
  Widget contentBox(BuildContext context) {
    final receiptNumber = receiptData['receiptNumber'];
    final payment = receiptData['payment'];
    final appointment = receiptData['appointment'];
    final patient = receiptData['patient'];
    final doctor = receiptData['doctor'];
    
    // Current date and time information
    final currentDateTime = "2025-06-01 19:05:49";
    final userLogin = "J33WAKASUPUN";
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: 450,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withBlue(170)],
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt,
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
                        'Payment Receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Thank you for your payment',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Receipt Content
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt header info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'RECEIPT #$receiptNumber',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${_formatDate(payment['createdAt'])}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(payment['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(payment['status']),
                            ),
                          ),
                          child: Text(
                            payment['status'],
                            style: TextStyle(
                              color: _getStatusColor(payment['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Information
                    _buildSectionHeader(context, 'Payment Information', Icons.payment, Colors.blue),
                    _buildInfoRow('Amount', '${payment['currency']} ${(payment['amount']/100).toStringAsFixed(2)}'),
                    if (payment['transactionDetails'] != null) ...[
                      if (payment['transactionDetails']['captureId'] != null)
                        _buildInfoRow('Transaction ID', payment['transactionDetails']['captureId']),
                      if (payment['transactionDetails']['paymentMethod'] != null)
                        _buildInfoRow('Payment Method', payment['transactionDetails']['paymentMethod']),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Doctor Information
                    _buildSectionHeader(context, 'Doctor Information', Icons.medical_services, Colors.green),
                    _buildInfoRow('Name', 'Dr. ${doctor['firstName']} ${doctor['lastName']}'),
                    _buildInfoRow('Email', doctor['email']),
                    if (doctor['specialization'] != null)
                      _buildInfoRow('Specialization', doctor['specialization']),
                    
                    const SizedBox(height: 24),
                    
                    // Patient Information
                    _buildSectionHeader(context, 'Patient Information', Icons.person, Colors.orange),
                    _buildInfoRow('Name', '${patient['firstName']} ${patient['lastName']}'),
                    _buildInfoRow('Email', patient['email']),
                    
                    const SizedBox(height: 24),
                    
                    // Appointment Information
                    _buildSectionHeader(context, 'Appointment Details', Icons.calendar_today, Colors.purple),
                    _buildInfoRow('Date', _formatDate(appointment['dateTime'])),
                    _buildInfoRow('Time', _formatTime(appointment['dateTime'])),
                    _buildInfoRow('Duration', '${appointment['duration']} minutes'),
                    _buildInfoRow('Reason for Visit', appointment['reasonForVisit']),
                    
                    // Session information
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): $currentDateTime',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current User\'s Login: $userLogin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thank you for choosing MediConnect!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _downloadPdf(context, payment['_id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData iconData, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Divider(color: color.withOpacity(0.2), thickness: 1),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'FAILED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  String _formatTime(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('h:mm a').format(date);
  }
  
  void _downloadPdf(BuildContext context, String paymentId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Processing Receipt'),
        content: Row(
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Text('Preparing your receipt...'),
            ),
          ],
        ),
      ),
    );
    
    try {
      if (kIsWeb) {
        print('Getting receipt token for payment: $paymentId');
        
        // Step 1: Get a receipt token from the backend
        final tokenResponse = await apiService.getReceiptToken(paymentId);
        
        // Close the loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        
        if (tokenResponse != null && tokenResponse['success'] == true) {
          final receiptToken = tokenResponse['data']['receiptToken'];
          
          // Step 2: Create URL to view the receipt with this token
          final baseUrl = 'http://192.168.1.159:3000'; // Your backend URL without /api
          final pdfUrl = '$baseUrl/api/payments/$paymentId/view-receipt?receiptToken=$receiptToken';
          
          print('Opening PDF URL: $pdfUrl');
          
          // Step 3: Open in a new browser tab
          html.window.open(pdfUrl, '_blank');
        } else {
          print('Failed to get receipt token: $tokenResponse');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to generate receipt token'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        print('Getting receipt token for payment: $paymentId');
        
        // Step 1: Get a receipt token from the backend
        final tokenResponse = await apiService.getReceiptToken(paymentId);
        
        // Close the loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        
        if (tokenResponse != null && tokenResponse['success'] == true) {
          final receiptToken = tokenResponse['data']['receiptToken'];
          
          // Step 2: Create URL to view the receipt with this token
          final baseUrl = 'http://192.168.1.159:3000'; // Your backend URL without /api
          final pdfUrl = '$baseUrl/api/payments/$paymentId/view-receipt?receiptToken=$receiptToken';
          
          print('Opening PDF URL: $pdfUrl');
          
          // For mobile, use getPaymentReceipt instead if available
          final filePath = await apiService.getPaymentReceipt(paymentId);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt saved to: $filePath'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          print('Failed to get receipt token: $tokenResponse');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to generate receipt token'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close the loading dialog if not already closed
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      print('Error downloading receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading receipt: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}