import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';

class DocumentHandler {
  static Future<void> downloadAndOpenDocument(
    BuildContext context, 
    String url, 
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        // For web, just launch the URL
        _launchUrl(context, url);
      } else if (Platform.isAndroid || Platform.isIOS) {
        await _downloadMobileDocument(context, url, fileName);
      } else {
        // Fallback for other platforms
        _launchUrl(context, url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling document: $e')),
      );
    }
  }
  
  // Simple URL launcher
  static Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening URL: $e')),
      );
    }
  }
  
  // Mobile document download and open
  static Future<void> _downloadMobileDocument(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    try {
      // Show downloading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading $fileName...')),
      );
      
      // Get app's temporary directory for storing the file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Download file with Dio
      final dio = Dio();
      await dio.download(url, filePath);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download complete. Opening $fileName...')),
      );
      
      // Open the file
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }
}