import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../../config/api_endpoints.dart';

class PaymentService extends BaseApiService {
  // Get receipt viewer URL
  String getReceiptViewerUrl(String paymentId) {
    // Get the current token
    final token = currentToken ?? '';

    // Use the base URL of your web app
    final appUrl = Uri.base.origin;

    // For debugging
    print('Creating receipt URL with token length: ${token.length}');

    // Encode the token for URL safety
    final encodedToken = Uri.encodeComponent(token);

    // Return the URL to the PDF viewer bridge with token and paymentId
    return '$appUrl/pdf_viewer.html?token=$encodedToken&id=$paymentId';
  }

// Get PDF URL directly
  String getReceiptPdfUrl(String paymentId) {
    // Get the base URL - adjust this to your actual backend URL in production
    final baseUrl = 'http://localhost:3000'; // Change to your backend URL

    // Get the auth token
    final token = Uri.encodeComponent(currentToken ?? '');

    // Return the URL to the PDF with token
    return '$baseUrl/api/payments/$paymentId/receipt-with-token?token=$token';
  }

// Create a payment (different from createPaymentOrder)
  Future<Map<String, dynamic>> createPayment({
    required String appointmentId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      final response = await post(
        ApiEndpoints.payments,
        data: {
          'appointmentId': appointmentId,
          'paymentMethod': paymentMethod,
          'amount': amount,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

// Verify a payment
  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String transactionId,
  }) async {
    try {
      final response = await post(
        ApiEndpoints.paymentVerify,
        data: {
          'paymentId': paymentId,
          'transactionId': transactionId,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

// Get all user payments
  Future<List<Map<String, dynamic>>> getUserPayments() async {
    try {
      final response = await get('${ApiEndpoints.payments}/user');
      if (response is Map &&
          response['success'] == true &&
          response['payments'] is List) {
        return List<Map<String, dynamic>>.from(response['payments']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

// Create a payment order (uses PayPal)
  Future<Map<String, dynamic>> createPaymentOrder({
    required String appointmentId,
    required double amount,
  }) async {
    try {
      final response = await post(
        '${ApiEndpoints.payments}/create-order',
        data: {
          'appointmentId': appointmentId,
          'amount': amount,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Capture a payment (confirms the PayPal payment)
  Future<Map<String, dynamic>> capturePayment(String orderId) async {
    try {
      final response = await post('${ApiEndpoints.payments}/capture/$orderId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get payment history
  Future<Map<String, dynamic>> getPaymentHistory({
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (status != null) 'status': status,
      };

      final response = await get('${ApiEndpoints.payments}/history',
          queryParams: queryParams);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get payment details
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      final response = await get('${ApiEndpoints.payments}/$paymentId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get payment for a specific appointment
  Future<Map<String, dynamic>> getPaymentForAppointment(
      String appointmentId) async {
    try {
      final response =
          await get('${ApiEndpoints.payments}/by-appointment/$appointmentId');

      if (response is Map) {
        return {'success': true, 'data': response['data']};
      } else {
        return {
          'success': false,
          'message': 'Failed to get payment information'
        };
      }
    } catch (e) {
      print('Error getting payment for appointment: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Request a refund
  Future<Map<String, dynamic>> requestRefund(
      {required String paymentId, required String reason}) async {
    try {
      final response = await post(
        '/payments/$paymentId/refund',
        data: {'reason': reason},
      );

      if (response is Map) {
        return {'success': true, 'data': response['data']};
      } else {
        return {'success': false, 'message': 'Failed to process refund'};
      }
    } catch (e) {
      print('Error processing refund: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get payment receipt
  Future<String> getPaymentReceipt(String paymentId) async {
    final receiptUrl =
        '${ApiEndpoints.baseUrl}${ApiEndpoints.payments}/$paymentId/receipt';
    return receiptUrl;
  }

  // Get PDF data for a receipt
  Future<Uint8List> getPaymentReceiptPdfData(String paymentId) async {
    try {
      // Get the token properly
      final token = await getToken();

      final response = await dio.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.payments}/$paymentId/receipt',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      } else {
        throw Exception(
            'Failed to download receipt: Status ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching receipt data: $e");
      rethrow;
    }
  }

  // Get authenticated receipt URL
  Future<String?> getAuthenticatedReceiptUrl(String paymentId) async {
    try {
      // Properly await the Future<String?> from getToken()
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not available');
      }

      final receiptUrl =
          '${ApiEndpoints.baseUrl}${ApiEndpoints.payments}/$paymentId/receipt';
      return '$receiptUrl?auth_token=$token';
    } catch (e) {
      print("Error generating authenticated receipt URL: $e");
      return null;
    }
  }

  // Get receipt token
  Future<Map<String, dynamic>?> getReceiptToken(String paymentId) async {
    try {
      final response = await get(
        '/payments/$paymentId/receipt-token',
      );
      return response;
    } catch (e) {
      print('Error getting receipt token: $e');
      return null;
    }
  }

  // Link payment to appointment
  Future<Map<String, dynamic>> linkPaymentToAppointment(
      String appointmentId, String paymentId) async {
    try {
      // Try a direct PATCH to update the appointment
      try {
        final response = await patch(
          '/appointments/$appointmentId',
          data: {
            'paymentId': paymentId,
          },
        );
        return response;
      } catch (e) {
        // If PATCH fails, try PUT instead (some APIs prefer PUT for updates)
        try {
          final response = await put(
            '/appointments/$appointmentId',
            data: {
              'paymentId': paymentId,
            },
          );
          return response;
        } catch (e2) {
          // As a final fallback, try a custom endpoint if available
          final response = await post(
            '/appointments/$appointmentId/payment',
            data: {
              'paymentId': paymentId,
            },
          );
          return response;
        }
      }
    } catch (e) {
      print("All methods failed to link payment: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getReceiptDetails(String paymentId) async {
    try {
      print('Getting receipt details for payment: $paymentId');

      final response = await get('/payments/$paymentId/receipt-details');

      if (response != null) {
        print('Receipt details obtained successfully');
        return response;
      }

      print('Failed to get receipt details');
      return null;
    } catch (e) {
      print('Error getting receipt details: $e');
      return null;
    }
  }
}
