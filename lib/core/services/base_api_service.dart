import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../config/api_endpoints.dart';

class BaseApiService {
  late Dio _dio;
  String? _authToken;

  BaseApiService() {
    print('Initializing BaseApiService with base URL: ${ApiEndpoints.baseUrl}');

    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) {
        return status != null && status < 500;
      },
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
    ));

    print('BaseApiService initialized');
  }

  void setAuthToken(String token) {
    print('Setting auth token: ${token.substring(0, 10)}...');
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  String? get currentToken => _authToken;

  String getAuthToken() {
    if (_authToken == null || _authToken!.isEmpty) {
      print('Warning: Auth token is missing or empty');
      return '';
    }
    return _authToken!;
  }

// Helper for full URL construction
  String getFullUrl(String endpoint) {
    return ApiEndpoints.getFullUrl(endpoint);
  }

  // Async method for operations that might need to refresh or fetch token
  Future<String?> getToken() async {
    return _authToken;
  }

  bool hasValidToken() {
    return _authToken != null && _authToken!.isNotEmpty;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw 'No authentication token available';
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }

  // Handle Dio Errors
  dynamic handleDioError(DioException e) {
    print('Handling DioError: ${e.message}');
    print('Response: ${e.response?.data}');

    if (e.response != null) {
      if (e.response?.data is Map) {
        final message = e.response?.data['message'] ?? 'An error occurred';
        return Exception(message);
      }
      return Exception(e.response?.data?.toString() ?? 'An error occurred');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Server not responding');
    } else {
      return Exception('Network error occurred');
    }
  }

  dynamic handleError(dynamic e) {
    if (e is DioException) {
      return handleDioError(e);
    } else {
      print('General API Error: $e');
      return Exception('Error: $e');
    }
  }

  // Helper methods for HTTP requests
  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response = await _dio.get(endpoint,
          queryParameters: queryParams, options: options);
      return response.data;
    } catch (e) {
      print('Error making GET request to $endpoint: $e');
      throw handleError(e); // Consistent error handling
    }
  }

  Future<dynamic> post(String endpoint,
      {dynamic data, Options? options}) async {
    try {
      final response = await _dio.post(endpoint, data: data, options: options);
      return response.data;
    } catch (e) {
      print('Error making POST request to $endpoint: $e');
      throw handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.put(endpoint, data: data, options: options);
      return response.data;
    } catch (e) {
      print('Error making PUT request to $endpoint: $e');
      throw handleError(e);
    }
  }

  Future<dynamic> patch(String endpoint,
      {dynamic data, Options? options}) async {
    try {
      final response = await _dio.patch(endpoint, data: data, options: options);
      return response.data;
    } catch (e) {
      print('Error making PATCH request to $endpoint: $e');
      throw handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint,
      {dynamic data, Options? options}) async {
    try {
      final response =
          await _dio.delete(endpoint, data: data, options: options);
      return response.data;
    } catch (e) {
      print('Error making DELETE request to $endpoint: $e');
      throw handleError(e);
    }
  }

  // Access to the Dio instance for specialized needs
  Dio get dio => _dio;
}
