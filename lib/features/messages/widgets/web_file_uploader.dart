import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

/// A file uploader that works on both web and mobile platforms
class WebSafeFileUploader {
  /// Upload a file in a platform-specific way that avoids _Namespace errors
  static Future<Map<String, dynamic>> uploadFile({
    required String url,
    required String token,
    required dynamic file, // Can be File, XFile, or bytes
    required Map<String, String> fields,
  }) async {
    if (kIsWeb) {
      return _uploadFileWeb(url, token, file, fields);
    } else {
      return _uploadFileMobile(url, token, file, fields);
    }
  }

  /// Web implementation that works around browser restrictions
  static Future<Map<String, dynamic>> _uploadFileWeb(
    String url,
    String token,
    dynamic file,
    Map<String, String> fields,
  ) async {
    try {
      print('WebSafeFileUploader: Using web-safe upload method');
      
      // Create a Dio instance for the request
      final dio = Dio();
      
      // Set authorization header
      dio.options.headers['Authorization'] = 'Bearer $token';
      
      // For web, we need to work with file data as bytes
      late Uint8List fileBytes;
      late String fileName;
      String? mimeType;
      
      // Extract file data based on type
      if (file is XFile) {
        fileBytes = await file.readAsBytes();
        fileName = file.name;
        mimeType = file.mimeType;
      } else if (file is File) {
        // For File objects on web (which might not be fully supported)
        try {
          fileBytes = await file.readAsBytes();
          fileName = file.path.split('/').last;
        } catch (e) {
          throw Exception('Web platform does not fully support File operations: $e');
        }
      } else if (file is Uint8List) {
        fileBytes = file;
        fileName = 'file_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        throw Exception('Unsupported file type for web upload');
      }
      
      // Create form data manually for web
      final formData = FormData();
      
      // Add the file
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: mimeType != null 
                ? MediaType.parse(mimeType) 
                : MediaType.parse(_getMimeTypeFromExtension(fileName)),
          ),
        ),
      );
      
      // Add all the field data
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });
      
      print('WebSafeFileUploader: Sending request to $url');
      print('WebSafeFileUploader: File name: $fileName, size: ${fileBytes.length} bytes');
      
      // Send the request using Dio
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          // Allow all response status codes to handle errors ourselves
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      
      print('WebSafeFileUploader: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Upload failed with status: ${response.statusCode}',
          'details': response.data.toString(),
        };
      }
    } catch (e) {
      print('Error in web file upload: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Mobile implementation using standard File APIs
  static Future<Map<String, dynamic>> _uploadFileMobile(
    String url,
    String token,
    dynamic file,
    Map<String, String> fields,
  ) async {
    try {
      print('WebSafeFileUploader: Using mobile upload method');
      
      // Get File object regardless of input type
      late File fileToUpload;
      
      if (file is XFile) {
        fileToUpload = File(file.path);
      } else if (file is File) {
        fileToUpload = file;
      } else {
        throw Exception('Unsupported file type for mobile upload');
      }
      
      // Create a multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          fileToUpload.path,
          contentType: MediaType.parse(_getMimeTypeFromExtension(fileToUpload.path)),
        ),
      );
      
      // Add the fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });
      
      print('WebSafeFileUploader: Sending mobile request to $url');
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('WebSafeFileUploader: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Upload failed with status: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Error in mobile file upload: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  /// Helper to determine MIME type from file extension
  static String _getMimeTypeFromExtension(String path) {
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
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}