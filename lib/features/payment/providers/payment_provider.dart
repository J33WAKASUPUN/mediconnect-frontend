import 'package:flutter/material.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _apiService;

  PaymentProvider({required ApiService apiService}) : _apiService = apiService;

  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _error;
  
  // For handling ongoing payment process
  bool _isProcessingPayment = false;
  String? _paymentId;
  
  // Getters
  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get error => _error;
  String? get paymentId => _paymentId;

  // Load all payments for the user
  Future<void> loadPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final jsonList = await _apiService.getUserPayments();
      _payments = jsonList.map((json) => Payment.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a payment
  Future<Map<String, dynamic>> initiatePayment({
    required String appointmentId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      _isProcessingPayment = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createPayment(
        appointmentId: appointmentId,
        paymentMethod: paymentMethod,
        amount: amount,
      );
      
      if (response['success']) {
        _paymentId = response['payment']['_id'];
      } else {
        _error = response['message'] ?? 'Failed to create payment';
      }
      
      _isProcessingPayment = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = e.toString();
      _isProcessingPayment = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  // Verify a payment
  Future<bool> verifyPayment({
    required String transactionId,
  }) async {
    if (_paymentId == null) {
      _error = 'No active payment to verify';
      notifyListeners();
      return false;
    }
    
    try {
      _isProcessingPayment = true;
      notifyListeners();

      final response = await _apiService.verifyPayment(
        paymentId: _paymentId!,
        transactionId: transactionId,
      );
      
      _isProcessingPayment = false;
      
      if (response['success']) {
        await loadPayments(); // Refresh payment list
        _paymentId = null; // Clear current payment
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to verify payment';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isProcessingPayment = false;
      _paymentId = null; // Clear on error
      notifyListeners();
      return false;
    }
  }

  // Get payment for a specific appointment
  Future<Payment?> getPaymentForAppointment(String appointmentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getPaymentForAppointment(appointmentId);
      
      _isLoading = false;
      
      if (response['success'] && response['payment'] != null) {
        final payment = Payment.fromJson(response['payment']);
        notifyListeners();
        return payment;
      } else {
        _error = response['message'] ?? 'No payment found for this appointment';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Reset payment process (e.g., when cancelling payment)
  void resetPaymentProcess() {
    _isProcessingPayment = false;
    _paymentId = null;
    _error = null;
    notifyListeners();
  }
}