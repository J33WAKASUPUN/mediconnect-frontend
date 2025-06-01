import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/payment_provider.dart';

class PaymentReceiptScreen extends StatefulWidget {
  final String paymentId;
  final String paymentReference;

  const PaymentReceiptScreen({
    super.key,
    required this.paymentId,
    required this.paymentReference,
  });

  @override
  _PaymentReceiptScreenState createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  bool _isLoading = false;
  String? _filePath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadReceipt();
  }

  Future<void> _downloadReceipt() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission is required to download receipts');
        }
      }

      // Use the provider to download the receipt
      final filePath = await Provider.of<PaymentProvider>(
        context, 
        listen: false
      ).downloadReceipt(widget.paymentId);

      if (!mounted) return;
      
      if (filePath != null) {
        setState(() {
          _filePath = filePath;
          _isLoading = false;
        });
        
        // Open the PDF automatically
        _openReceipt(filePath);
      } else {
        setState(() {
          _errorMessage = 'Could not download receipt';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openReceipt(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done) {
        // If opening fails, show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              action: SnackBarAction(
                label: 'Download',
                onPressed: _shareFile,
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            action: SnackBarAction(
              label: 'Download',
              onPressed: _shareFile,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Share or save the file using platform-specific methods
  void _shareFile() {
    // Implement sharing functionality if needed
    // You could use the share_plus package for this
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Payment Receipt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header section
          Container(
            color: AppColors.primary,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Access and view your payment receipt',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator(message: 'Downloading receipt...'))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error Downloading Receipt',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: _downloadReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Receipt Downloaded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reference: ${widget.paymentReference}',
                style: TextStyle(
                  fontFamily: 'Monospace',
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_filePath != null)
              Column(
                children: [
                  Text(
                    'Your receipt has been downloaded to your device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Receipt'),
                    onPressed: () => _openReceipt(_filePath!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
              label: Text(
                'Back to Payments',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}