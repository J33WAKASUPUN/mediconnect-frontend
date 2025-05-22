import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class CrossPlatformFileUploader {
  /// Upload a file that works on both web and mobile
  static Future<Map<String, dynamic>> uploadFile({
    required String url,
    required String token,
    required dynamic file, // Can be File or XFile 
    required Map<String, String> fields,
  }) async {
    try {
      if (kIsWeb) {
        return _uploadFileWeb(url, token, file, fields);
      } else {
        return _uploadFileMobile(url, token, file, fields);
      }
    } catch (e) {
      print('Error in CrossPlatformFileUploader: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _uploadFileWeb(
    String url,
    String token,
    dynamic file,
    Map<String, String> fields,
  ) async {
    try {
      print('CrossPlatformFileUploader: Using web upload method');
      
      // Create a Dio instance for web
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Handle both File and XFile types
      late List<int> bytes;
      late String fileName;
      
      // Get file data based on type
      if (file is XFile) {
        bytes = await file.readAsBytes();
        fileName = path.basename(file.name);
      } else if (file is File) {
        bytes = await file.readAsBytes();
        fileName = path.basename(file.path);
      } else {
        throw Exception('Unsupported file type');
      }
      
      // Create form data with required fields
      final formData = FormData();
      
      // Add all text fields
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });
      
      // Add the file
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: MediaType.parse(_getContentType(fileName)),
          ),
        ),
      );
      
      print('CrossPlatformFileUploader: Sending request to $url');
      
      // Use Dio to send the request
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          validateStatus: (status) => true,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );
      
      print('CrossPlatformFileUploader: Response status: ${response.statusCode}');
      
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

  static Future<Map<String, dynamic>> _uploadFileMobile(
    String url,
    String token,
    dynamic file,
    Map<String, String> fields,
  ) async {
    try {
      print('CrossPlatformFileUploader: Using mobile upload method');
      
      // Convert XFile to File if needed
      File fileToUpload;
      if (file is XFile) {
        fileToUpload = File(file.path);
      } else if (file is File) {
        fileToUpload = file;
      } else {
        throw Exception('Unsupported file type');
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          fileToUpload.path,
          contentType: MediaType.parse(_getContentType(fileToUpload.path)),
        ),
      );
      
      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('CrossPlatformFileUploader: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body)['data'],
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
  
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    
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