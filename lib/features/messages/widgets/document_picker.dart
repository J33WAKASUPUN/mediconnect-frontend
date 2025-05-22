import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:universal_html/html.dart' as html;

/// A platform-aware document picker that works on both web and mobile
class DocumentPicker {
  /// Pick a document with proper platform handling
  static Future<PickedDocument?> pickDocument(BuildContext context) async {
    try {
      if (kIsWeb) {
        // For web, use a direct HTML approach to avoid FilePicker initialization issues
        return await _pickDocumentWeb(context);
      } else {
        // For mobile, use FilePicker as usual
        return await _pickDocumentMobile();
      }
    } catch (e) {
      print('Error in DocumentPicker.pickDocument: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick document: $e')),
      );
      return null;
    }
  }

  /// Web-specific document picking that avoids FilePicker
  static Future<PickedDocument?> _pickDocumentWeb(BuildContext context) async {
    // Create a file input element
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.pdf,.doc,.docx,.xls,.xlsx,.txt'
      ..click();

    // Wait for a file to be selected
    final completer = Completer<PickedDocument?>();
    
    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          if (reader.result != null) {
            // Convert to Uint8List
            final bytes = Uint8List.fromList(reader.result as List<int>);
            
            completer.complete(PickedDocument(
              name: file.name,
              bytes: bytes,
              size: file.size,
              mimeType: file.type,
            ));
          } else {
            completer.complete(null);
          }
        });
      } else {
        completer.complete(null);
      }
    });

    // Handle the case where the user cancels the picker
    uploadInput.onAbort.listen((event) {
      if (!completer.isCompleted) completer.complete(null);
    });

    // Set a timeout for the picker
    Future.delayed(Duration(seconds: 60), () {
      if (!completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  /// Mobile-specific document picking using FilePicker
  static Future<PickedDocument?> _pickDocumentMobile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      withData: true, // Get bytes too for consistency with web
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    
    if (file.path != null) {
      return PickedDocument(
        name: file.name,
        path: file.path,
        bytes: file.bytes,
        size: file.size,
        mimeType: _getMimeTypeFromExtension(file.extension ?? ''),
      );
    }
    
    return null;
  }
  
  /// Helper to determine MIME type from file extension
  static String _getMimeTypeFromExtension(String extension) {
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
      default:
        return 'application/octet-stream';
    }
  }
}

/// Class to represent picked documents across platforms
class PickedDocument {
  final String name;
  final String? path;  // Will be null on web
  final Uint8List? bytes;
  final int? size;
  final String mimeType;

  PickedDocument({
    required this.name,
    this.path,
    this.bytes,
    this.size,
    required this.mimeType,
  });
  
  /// Get file as File object for mobile platforms
  File? get file {
    if (path != null && !kIsWeb) {
      return File(path!);
    }
    return null;
  }
  
  /// Check if this is a valid document that can be uploaded
  bool get isValid {
    return kIsWeb 
        ? bytes != null && bytes!.isNotEmpty
        : path != null && path!.isNotEmpty;
  }
}