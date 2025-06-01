import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

/// Callback type for progress updates during upload
typedef ProgressCallback = void Function(double progress, String message);

/// Callback type for status updates during upload
typedef StatusCallback = void Function(String status, {bool isError});

/// A specialized image uploader for AI health assistant features with enhanced UI feedback
class AIImageUploader {

  /// Upload a medical image to be analyzed by the AI with enhanced UI feedback
  static Future<Map<String, dynamic>> uploadImageForAnalysis({
    required String url,
    required String token,
    required dynamic image, // Can be File, XFile, or bytes
    required String prompt,
    required String sessionId,
    ProgressCallback? onProgress,
    StatusCallback? onStatusUpdate,
  }) async {
    onStatusUpdate?.call('Preparing image for analysis...', isError: false);
    
    if (kIsWeb) {
      return _uploadImageWeb(url, token, image, prompt, sessionId, onProgress, onStatusUpdate);
    } else {
      return _uploadImageMobile(url, token, image, prompt, sessionId, onProgress, onStatusUpdate);
    }
  }

  /// Web implementation for image upload with enhanced UI feedback
  static Future<Map<String, dynamic>> _uploadImageWeb(
    String url,
    String token,
    dynamic image,
    String prompt,
    String sessionId,
    ProgressCallback? onProgress,
    StatusCallback? onStatusUpdate,
  ) async {
    try {
      onStatusUpdate?.call('Setting up secure connection...', isError: false);
      print('AIImageUploader: Using web upload method');
      
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Process image data with user feedback
      onStatusUpdate?.call('Processing image data...', isError: false);
      late Uint8List imageBytes;
      late String fileName;
      String? mimeType;
      
      if (image is XFile) {
        onStatusUpdate?.call('Reading image file...', isError: false);
        imageBytes = await image.readAsBytes();
        fileName = image.name;
        mimeType = image.mimeType;
      } else if (image is File) {
        try {
          onStatusUpdate?.call('Reading image file...', isError: false);
          imageBytes = await image.readAsBytes();
          fileName = image.path.split('/').last;
        } catch (e) {
          onStatusUpdate?.call('Error: Web platform limitation encountered', isError: true);
          throw Exception('Web platform does not fully support File operations: $e');
        }
      } else if (image is Uint8List) {
        imageBytes = image;
        fileName = 'medical_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        onStatusUpdate?.call('Error: Unsupported image format', isError: true);
        throw Exception('Unsupported image type for analysis');
      }
      
      // Validate image size for better UX
      final imageSizeMB = imageBytes.length / (1024 * 1024);
      if (imageSizeMB > 10) {
        onStatusUpdate?.call('Warning: Large image detected (${imageSizeMB.toStringAsFixed(1)}MB)', isError: false);
      }
      
      onStatusUpdate?.call('Creating upload request...', isError: false);
      
      // Create form data for the request
      final formData = FormData();
      
      // Add the image file
      formData.files.add(
        MapEntry(
          'image',  // Field name expected by backend
          MultipartFile.fromBytes(
            imageBytes,
            filename: fileName,
            contentType: mimeType != null 
                ? MediaType.parse(mimeType) 
                : MediaType.parse(_getImageMimeType(fileName)),
          ),
        ),
      );
      
      // Add the prompt and sessionId
      formData.fields.add(MapEntry('prompt', prompt));
      formData.fields.add(MapEntry('sessionId', sessionId));
      
      print('AIImageUploader: Sending request to $url');
      print('AIImageUploader: Image name: $fileName, size: ${imageBytes.length} bytes');
      print('AIImageUploader: Using sessionId: $sessionId');
      
      onStatusUpdate?.call('Uploading to AI service...', isError: false);
      onProgress?.call(0.0, 'Starting upload...');
      
      // Add a cancellation token and progress tracking
      final cancelToken = CancelToken();
      
      // Send the request with timeout and progress tracking
      final response = await dio.post(
        url,
        data: formData,
        cancelToken: cancelToken,
        options: Options(
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
          headers: {
            'Accept': 'application/json',
          },
        ),
        onSendProgress: (sent, total) {
          final progress = sent / total;
          final percentage = (progress * 100).toInt();
          
          // Enhanced progress feedback
          String progressMessage;
          if (percentage < 25) {
            progressMessage = 'Uploading image...';
          } else if (percentage < 75) {
            progressMessage = 'Processing data...';
          } else if (percentage < 95) {
            progressMessage = 'Almost complete...';
          } else {
            progressMessage = 'Finalizing upload...';
          }
          
          onProgress?.call(progress, progressMessage);
          onStatusUpdate?.call('$progressMessage ($percentage%)', isError: false);
          print('AIImageUploader: Upload progress: $percentage%');
        },
      );
      
      print('AIImageUploader: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        onStatusUpdate?.call('✅ Analysis completed successfully!', isError: false);
        onProgress?.call(1.0, 'Complete!');
        
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'Image analysis completed successfully',
          'ui_message': '✅ Your image has been successfully analyzed!',
        };
      } else {
        final errorMsg = response.data['message'] ?? 'Analysis failed (Status: ${response.statusCode})';
        onStatusUpdate?.call('❌ $errorMsg', isError: true);
        
        return {
          'success': false,
          'message': errorMsg,
          'details': response.data.toString(),
          'ui_message': '❌ Upload failed. Please try again.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      final errorMessage = _getUserFriendlyErrorMessage(e);
      onStatusUpdate?.call('❌ $errorMessage', isError: true);
      print('Error in AI image upload: $e');
      
      return {
        'success': false,
        'message': e.toString(),
        'details': 'Exception occurred during image upload',
        'ui_message': '❌ $errorMessage',
      };
    }
  }

  /// Mobile implementation for image upload with enhanced UI feedback
  static Future<Map<String, dynamic>> _uploadImageMobile(
    String url,
    String token,
    dynamic image,
    String prompt,
    String sessionId,
    ProgressCallback? onProgress,
    StatusCallback? onStatusUpdate,
  ) async {
    try {
      onStatusUpdate?.call('Preparing mobile upload...', isError: false);
      print('AIImageUploader: Using mobile upload method');
      
      // Get File object from image
      late File imageFile;
      
      if (image is XFile) {
        onStatusUpdate?.call('Processing selected image...', isError: false);
        imageFile = File(image.path);
      } else if (image is File) {
        imageFile = image;
      } else {
        onStatusUpdate?.call('Error: Unsupported image type', isError: true);
        throw Exception('Unsupported image type for mobile upload');
      }
      
      // Check file size for better UX
      final fileSize = await imageFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      if (fileSizeMB > 10) {
        onStatusUpdate?.call('Warning: Large file detected (${fileSizeMB.toStringAsFixed(1)}MB)', isError: false);
      }
      
      onStatusUpdate?.call('Creating secure connection...', isError: false);
      
      // Create a multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      onStatusUpdate?.call('Preparing image data...', isError: false);
      
      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',  // Field name expected by backend
          imageFile.path,
          contentType: MediaType.parse(_getImageMimeType(imageFile.path)),
        ),
      );
      
      // Add prompt and sessionId
      request.fields['prompt'] = prompt;
      request.fields['sessionId'] = sessionId;
      
      print('AIImageUploader: Sending mobile request to $url');
      print('AIImageUploader: Using field name: image for file upload');
      print('AIImageUploader: Using sessionId: $sessionId');
      
      onStatusUpdate?.call('🚀 Uploading to AI service...', isError: false);
      onProgress?.call(0.3, 'Connecting to server...');
      
      // Send the request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          onStatusUpdate?.call('❌ Connection timeout - please try again', isError: true);
          throw TimeoutException('Request timed out after 120 seconds');
        },
      );
      
      onProgress?.call(0.8, 'Processing response...');
      onStatusUpdate?.call('Receiving analysis results...', isError: false);
      
      final response = await http.Response.fromStream(streamedResponse);
      
      print('AIImageUploader: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        onProgress?.call(1.0, 'Complete!');
        onStatusUpdate?.call('✅ Analysis completed successfully!', isError: false);
        
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Image analysis completed successfully',
          'ui_message': '✅ Your medical image has been successfully analyzed!',
        };
      } else {
        String errorMessage = 'Image analysis failed';
        Map<String, dynamic>? responseBody;
        
        try {
          responseBody = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = responseBody['message'] ?? errorMessage;
        } catch (e) {
          // Handle case where response body isn't valid JSON
          errorMessage = 'Server returned invalid response';
        }
        
        final userFriendlyError = _getHttpErrorMessage(response.statusCode);
        onStatusUpdate?.call('❌ $userFriendlyError', isError: true);
        
        return {
          'success': false,
          'message': errorMessage,
          'details': responseBody?.toString() ?? response.body,
          'statusCode': response.statusCode,
          'ui_message': '❌ $userFriendlyError',
        };
      }
    } catch (e) {
      final errorMessage = _getUserFriendlyErrorMessage(e);
      onStatusUpdate?.call('❌ $errorMessage', isError: true);
      print('Error in mobile AI image upload: $e');
      
      return {
        'success': false,
        'message': e.toString(),
        'details': 'Exception occurred during image upload',
        'ui_message': '❌ $errorMessage',
      };
    }
  }
  
  /// Helper to determine image MIME type
  static String _getImageMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';  // Default to jpeg for unknown types
    }
  }
  
  /// Get user-friendly error messages for better UX
  static String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      return 'Connection timeout. Please check your internet and try again.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('file') || errorString.contains('read')) {
      return 'Could not read the image file. Please try selecting another image.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please allow access to your files.';
    } else if (errorString.contains('size') || errorString.contains('large')) {
      return 'Image file is too large. Please try a smaller image.';
    } else if (errorString.contains('format') || errorString.contains('type')) {
      return 'Unsupported image format. Please use JPG, PNG, or WebP.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
  
  /// Get user-friendly HTTP error messages
  static String _getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your image and try again.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'Access denied. You may not have permission for this action.';
      case 404:
        return 'Service not found. Please contact support.';
      case 413:
        return 'Image file is too large. Please try a smaller image.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again in a few moments.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'Upload failed. Please try again.';
    }
  }
}

/// Custom exception for timeout with better UI messaging
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}

/// Helper class for UI state management during upload
class UploadState {
  final bool isUploading;
  final double progress;
  final String message;
  final bool hasError;
  final String? errorMessage;

  const UploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.message = '',
    this.hasError = false,
    this.errorMessage,
  });

  UploadState copyWith({
    bool? isUploading,
    double? progress,
    String? message,
    bool? hasError,
    String? errorMessage,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}