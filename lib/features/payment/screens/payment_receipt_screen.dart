import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
    Key? key,
    required this.paymentId,
    required this.paymentReference,
  }) : super(key: key);

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
      appBar: AppBar(
        title: const Text('Payment Receipt'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Downloading receipt...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error downloading receipt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _downloadReceipt,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Receipt Downloaded',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Payment Reference: ${widget.paymentReference}'),
          const SizedBox(height: 24),
          if (_filePath != null)
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_new),
              label: const Text('Open Receipt'),
              onPressed: () => _openReceipt(_filePath!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Payments'),
          ),
        ],
      ),
    );
  }
}