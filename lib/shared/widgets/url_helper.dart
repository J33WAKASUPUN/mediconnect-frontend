import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  // Open URL in external browser
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening URL: $e');
      return false;
    }
  }

  // Show URL action dialog
  static Future<void> showUrlActionDialog(
    BuildContext context,
    String url,
    String title,
    String message, {
    String buttonText = 'Open in Browser',
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            SizedBox(height: 16),
            Text(
              'URL: ${url.length > 30 ? '${url.substring(0, 30)}...' : url}',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openUrl(url);
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}