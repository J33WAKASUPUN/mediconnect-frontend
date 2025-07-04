import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _apiService;

  PaymentProvider({required ApiService apiService}) : _apiService = apiService;

  List<Payment> _payments = [];
  int _totalPayments = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // PayPal payment process variables
  bool _isProcessingPayment = false;
  String? _currentOrderId;
  String? _paypalApprovalUrl;

  // For payment details
  Payment? _selectedPayment;
  bool _isLoadingDetails = false;

  // Getters
  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isProcessingPayment => _isProcessingPayment;
  bool get hasMore => _payments.length < _totalPayments;
  String? get error => _error;
  String? get currentOrderId => _currentOrderId;
  String? get paypalApprovalUrl => _paypalApprovalUrl;
  Payment? get selectedPayment => _selectedPayment;
  bool get isLoadingDetails => _isLoadingDetails;

  // Load payments history
  Future<void> loadPaymentHistory({bool refresh = false}) async {
    // Check if we're already loading to prevent duplicate calls
    if (_isLoading || _isLoadingMore) return;

    if (refresh) {
      _currentPage = 1;
      _isLoading = true;
    } else if (!hasMore && !refresh) {
      return;
    } else {
      _isLoadingMore = true;
    }

    _error = null;

    // IMPORTANT: Schedule this notification for the next frame to avoid build-phase issues
    // Instead of calling notifyListeners() directly, use this:
    Future.microtask(() => notifyListeners());

    try {
      final response = await _apiService.getPaymentHistory(
        page: _currentPage,
        limit: 10,
      );

      final paymentsData = response['data']['payments'] as List<dynamic>;
      final payments =
          paymentsData.map((json) => Payment.fromJson(json)).toList();

      if (refresh) {
        _payments = payments;
      } else {
        _payments.addAll(payments);
      }

      _totalPayments = response['data']['pagination']['totalRecords'];
      _currentPage++;

      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  String? getPaymentStatusForAppointment(String appointmentId) {
    try {
      final payment = _payments.firstWhere(
        (p) => p.appointmentId == appointmentId,
      );
      return payment.status;
    } catch (e) {
      return null;
    }
  }

  // Create a payment order with PayPal
  Future<Map<String, dynamic>> createPaymentOrder({
    required String appointmentId,
    required double amount,
  }) async {
    try {
      _isProcessingPayment = true;
      _error = null;
      _currentOrderId = null;
      _paypalApprovalUrl = null;
      notifyListeners();

      print(
          "Creating payment order for appointment: $appointmentId with amount: $amount");

      final response = await _apiService.createPaymentOrder(
        appointmentId: appointmentId,
        amount: amount,
      );

      print("Payment order creation response: $response");

      // Extract the actual data from the nested structure
      final bool success = response['status'] == 'success';
      if (success && response['data'] != null) {
        // Navigate through the nested structure: response -> data -> data
        final paymentData = response['data']['data'];
        if (paymentData != null) {
          _currentOrderId = paymentData['orderId'];

          // Find the approval URL from the links
          if (paymentData['links'] != null) {
            final links = paymentData['links'] as List<dynamic>;
            for (var link in links) {
              if (link['rel'] == 'approve') {
                _paypalApprovalUrl = link['href'];
                break;
              }
            }
          }

          _isProcessingPayment = false;
          notifyListeners();
          return {'success': true, 'data': paymentData};
        }
      }

      // If we got here, something went wrong with parsing the response
      _error = 'Unable to process payment: Invalid response format';
      _isProcessingPayment = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    } catch (e) {
      _error = e.toString();
      _isProcessingPayment = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  BuildContext? _context;

// Add this method
  void setContext(BuildContext context) {
    _context = context;
  }

  // Capture payment after PayPal approval
  Future<bool> capturePayment() async {
    if (_currentOrderId == null) {
      _error = 'No active payment order to capture';
      notifyListeners();
      return false;
    }

    try {
      _isProcessingPayment = true;
      notifyListeners();

      final response = await _apiService.capturePayment(_currentOrderId!);

      _isProcessingPayment = false;

      if (response['status'] == 'success') {
        // Extract payment ID and appointment ID from the response
        String? paymentId;
        String? appointmentId;

        if (response['data'] != null) {
          if (response['data']['paymentId'] != null) {
            paymentId = response['data']['paymentId'].toString();
          }
          if (response['data']['appointmentId'] != null) {
            appointmentId = response['data']['appointmentId'].toString();
          }
        }

        // DEBUG: Print the response data
        print("Payment success! Response data: ${response['data']}");
        print("Payment ID: $paymentId, Appointment ID: $appointmentId");

        // Register the payment locally
        if (appointmentId != null) {
          // Access the AppointmentProvider from the context
          if (_context != null) {
            try {
              final appointmentProvider =
                  Provider.of<AppointmentProvider>(_context!, listen: false);
              appointmentProvider.registerPaymentForAppointment(
                  appointmentId, paymentId ?? _currentOrderId!);
              print(
                  "Payment registered locally for appointment: $appointmentId");
            } catch (e) {
              print("Error registering payment locally: $e");
            }
          }
        }

        // Refresh payment list
        await loadPaymentHistory(refresh: true);

        // Clear current payment
        _currentOrderId = null;
        _paypalApprovalUrl = null;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to capture payment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isProcessingPayment = false;
      _currentOrderId = null;
      _paypalApprovalUrl = null;
      notifyListeners();
      return false;
    }
  }

  // Get payment details
  Future<Payment?> getPaymentDetails(String paymentId) async {
    try {
      _isLoadingDetails = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getPaymentDetails(paymentId);

      _isLoadingDetails = false;

      if (response['status'] == 'success' && response['data'] != null) {
        _selectedPayment = Payment.fromJson(response['data']);
        notifyListeners();
        return _selectedPayment;
      } else {
        _error = response['message'] ?? 'Failed to get payment details';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoadingDetails = false;
      notifyListeners();
      return null;
    }
  }

  // Download payment receipt
  Future<String?> downloadReceipt(String paymentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print("Starting receipt download for payment: $paymentId");
      final String filePath = await _apiService.getPaymentReceipt(paymentId);

      _isLoading = false;
      notifyListeners();

      return filePath;
    } catch (e) {
      print("Error downloading receipt: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Uint8List> getReceiptPdfData(String paymentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print("Fetching receipt PDF data for payment: $paymentId");
      final Uint8List pdfData =
          await _apiService.getPaymentReceiptPdfData(paymentId);

      _isLoading = false;
      notifyListeners();

      return pdfData;
    } catch (e) {
      print("Error downloading receipt data: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Handle PayPal payment flow
  Future<bool> handlePayPalPayment(String appointmentId, double amount) async {
    try {
      // Step 1: Create a payment order
      final orderResult = await createPaymentOrder(
        appointmentId: appointmentId,
        amount: amount,
      );

      if (orderResult['status'] != 'success' || _paypalApprovalUrl == null) {
        return false;
      }

      // Step 2: Open PayPal approval URL in a browser
      if (await canLaunchUrl(Uri.parse(_paypalApprovalUrl!))) {
        await launchUrl(
          Uri.parse(_paypalApprovalUrl!),
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        _error = 'Could not launch PayPal payment URL';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reset payment process (e.g., when cancelling payment)
  void resetPaymentProcess() {
    _isProcessingPayment = false;
    _currentOrderId = null;
    _paypalApprovalUrl = null;
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getReceiptDetails(String paymentId) async {
    try {
      print('Getting receipt details for payment: $paymentId');

      final response = await _apiService.getReceiptDetails(paymentId);

      if (response != null && response['success'] == true) {
        print('Receipt details obtained successfully');
        return response;
      }

      _error = response?['message'] ?? 'Failed to get receipt details';
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('Error getting receipt details: $e');
      return null;
    }
  }
}
