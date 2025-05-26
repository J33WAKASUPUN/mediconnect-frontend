import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

/// A specialized image uploader for AI health assistant features
class AIImageUploader {
  /// Upload a medical image to be analyzed by the AI
  static Future<Map<String, dynamic>> uploadImageForAnalysis({
    required String url,
    required String token,
    required dynamic image, // Can be File, XFile, or bytes
    required String prompt,
    required String sessionId, // Add sessionId parameter
  }) async {
    if (kIsWeb) {
      return _uploadImageWeb(url, token, image, prompt, sessionId);
    } else {
      return _uploadImageMobile(url, token, image, prompt, sessionId);
    }
  }

  /// Web implementation for image upload
  static Future<Map<String, dynamic>> _uploadImageWeb(
    String url,
    String token,
    dynamic image,
    String prompt,
    String sessionId, // Add sessionId
  ) async {
    try {
      print('AIImageUploader: Using web upload method');
      
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Process image data
      late Uint8List imageBytes;
      late String fileName;
      String? mimeType;
      
      if (image is XFile) {
        imageBytes = await image.readAsBytes();
        fileName = image.name;
        mimeType = image.mimeType;
      } else if (image is File) {
        try {
          imageBytes = await image.readAsBytes();
          fileName = image.path.split('/').last;
        } catch (e) {
          throw Exception('Web platform does not fully support File operations: $e');
        }
      } else if (image is Uint8List) {
        imageBytes = image;
        fileName = 'medical_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        throw Exception('Unsupported image type for analysis');
      }
      
      // Create form data for the request
      final formData = FormData();
      
      // IMPORTANT: Use 'image' as the field name to match backend configuration
      formData.files.add(
        MapEntry(
          'image',  // This must match the field name expected by multer in your backend
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
      formData.fields.add(MapEntry('sessionId', sessionId)); // Add sessionId
      
      print('AIImageUploader: Sending request to $url');
      print('AIImageUploader: Image name: $fileName, size: ${imageBytes.length} bytes');
      print('AIImageUploader: Using sessionId: $sessionId');
      
      // Send the request
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      
      print('AIImageUploader: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Image analysis failed with status: ${response.statusCode}',
          'details': response.data.toString(),
        };
      }
    } catch (e) {
      print('Error in AI image upload: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Mobile implementation for image upload
  static Future<Map<String, dynamic>> _uploadImageMobile(
    String url,
    String token,
    dynamic image,
    String prompt,
    String sessionId, // Add sessionId
  ) async {
    try {
      print('AIImageUploader: Using mobile upload method');
      
      // Get File object from image
      late File imageFile;
      
      if (image is XFile) {
        imageFile = File(image.path);
      } else if (image is File) {
        imageFile = image;
      } else {
        throw Exception('Unsupported image type for mobile upload');
      }
      
      // Create a multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // IMPORTANT: Use 'image' as the field name to match backend configuration
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',  // This must match the field name expected by multer
          imageFile.path,
          contentType: MediaType.parse(_getImageMimeType(imageFile.path)),
        ),
      );
      
      // Add prompt and sessionId
      request.fields['prompt'] = prompt;
      request.fields['sessionId'] = sessionId; // Add sessionId
      
      print('AIImageUploader: Sending mobile request to $url');
      print('AIImageUploader: Using field name: image for file upload');
      print('AIImageUploader: Using sessionId: $sessionId');
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('AIImageUploader: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Image analysis failed with status: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Error in mobile AI image upload: $e');
      return {
        'success': false,
        'message': e.toString(),
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
      default:
        return 'image/jpeg';  // Default to jpeg for unknown types
    }
  }
}