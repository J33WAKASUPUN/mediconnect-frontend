import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;

class PlatformFilePicker {
  /// Pick a document file that works on both web and mobile
  static Future<PickedFile?> pickDocument() async {
    try {
      // Create options appropriate for web
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: false,
        withData: true, // Important for web
        onFileLoading: (FilePickerStatus status) {
          print('File picker status: $status');
        },
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      // Handle both platforms
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('Could not read file bytes for web platform');
        }
        
        return PickedFile(
          bytes: file.bytes!,
          name: file.name,
          extension: file.extension ?? '',
          size: file.size,
          path: null,
        );
      } else {
        if (file.path == null) {
          throw Exception('No valid file path available for mobile platform');
        }
        
        return PickedFile(
          bytes: null,
          name: file.name,
          extension: file.extension ?? '',
          size: file.size,
          path: file.path,
        );
      }
    } catch (e) {
      print('Error in PlatformFilePicker.pickDocument: $e');
      rethrow;
    }
  }

  /// Pick an image file that works on both web and mobile
  static Future<PickedFile?> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for web
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      // Handle both platforms
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('Could not read file bytes for web platform');
        }
        
        return PickedFile(
          bytes: file.bytes!,
          name: file.name,
          extension: file.extension ?? '',
          size: file.size,
          path: null,
        );
      } else {
        if (file.path == null) {
          throw Exception('No valid file path available for mobile platform');
        }
        
        return PickedFile(
          bytes: null,
          name: file.name,
          extension: file.extension ?? '',
          size: file.size,
          path: file.path,
        );
      }
    } catch (e) {
      print('Error in PlatformFilePicker.pickImage: $e');
      rethrow;
    }
  }
  
  /// Get MIME type from file extension
  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
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
        return 'application/octet-stream';
    }
  }
}

/// Class to represent picked files across platforms
class PickedFile {
  final Uint8List? bytes; // For web
  final String? path;     // For mobile
  final String name;
  final String extension;
  final int size;

  const PickedFile({
    required this.bytes,
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
  });
  
  /// Get file as io.File for mobile platforms
  io.File? get file {
    if (path != null && !kIsWeb) {
      return io.File(path!);
    }
    return null;
  }
  
  /// Get MIME type based on extension
  String get mimeType {
    return PlatformFilePicker.getMimeType(extension);
  }
  
  /// Check if it's an image
  bool get isImage {
    final ext = extension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}