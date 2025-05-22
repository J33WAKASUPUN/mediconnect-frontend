import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class MessageFileViewer extends StatefulWidget {
  final Message message;
  final bool isPreview; // If true, shows a smaller preview version

  const MessageFileViewer({
    Key? key,
    required this.message,
    this.isPreview = false,
  }) : super(key: key);

  @override
  State<MessageFileViewer> createState() => _MessageFileViewerState();
}

class _MessageFileViewerState extends State<MessageFileViewer> {
  bool _isLoading = false;

  // Check if the message contains a file
  bool get hasFile => widget.message.file != null &&
      widget.message.file!['url'] != null &&
      widget.message.file!['contentType'] != null;
  
  // Check if file is an image
  bool get isImage => hasFile && 
      widget.message.file!['contentType'].toString().startsWith('image/');
  
  // Check if file is a PDF
  bool get isPdf => hasFile && 
      widget.message.file!['contentType'].toString() == 'application/pdf';
  
  // Get file name
  String get fileName => hasFile ? 
      (widget.message.file!['filename'] ?? 'file') : 'file';
  
  // Get file URL
  String get fileUrl => hasFile ? widget.message.file!['url'] : '';
  
  // Get file content type
  String get fileContentType => hasFile ? 
      widget.message.file!['contentType'] : 'application/octet-stream';

  @override
  Widget build(BuildContext context) {
    if (!hasFile) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File content display based on type
        if (isImage)
          _buildImageViewer()
        else if (isPdf && !widget.isPreview)
          _buildPdfViewer()
        else
          _buildGenericFileViewer(),

        // File actions (download, share, etc)
        if (!widget.isPreview)
          _buildFileActions(),
      ],
    );
  }
  
  // Build a widget for image files
  Widget _buildImageViewer() {
    return GestureDetector(
      onTap: widget.isPreview ? _openFullViewer : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: fileUrl,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.red[100],
            child: const Icon(Icons.error),
          ),
          fit: widget.isPreview ? BoxFit.cover : BoxFit.contain,
          height: widget.isPreview ? 150 : null,
          width: widget.isPreview ? double.infinity : null,
        ),
      ),
    );
  }
  
  // Build a PDF viewer
  Widget _buildPdfViewer() {
    if (kIsWeb) {
      // For web, just show a link to open the PDF
      return InkWell(
        onTap: () => _launchUrl(fileUrl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Click to open PDF'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // For mobile, download and show the PDF
      return FutureBuilder<String>(
        future: _downloadFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Container(
              height: 100,
              color: Colors.red[100],
              child: Center(child: Text('Failed to load PDF: ${snapshot.error}')),
            );
          } else {
            return Container(
              height: 400,
              child: PDFView(
                filePath: snapshot.data!,
                enableSwipe: true,
                swipeHorizontal: true,
                autoSpacing: false,
                pageFling: false,
              ),
            );
          }
        },
      );
    }
  }
  
  // Build a generic file viewer for other file types
  Widget _buildGenericFileViewer() {
    final fileIcon = _getFileIcon();
    final fileColor = _getFileColor();
    
    return InkWell(
      onTap: widget.isPreview ? _openFullViewer : null,
      child: Container(
        padding: EdgeInsets.all(widget.isPreview ? 8 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(fileIcon, color: fileColor, size: widget.isPreview ? 24 : 40),
            SizedBox(width: widget.isPreview ? 8 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.isPreview ? 12 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.isPreview)
                    Text(
                      _formatFileSize(),
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build file action buttons
  Widget _buildFileActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // View button (only for non-image, non-PDF files)
          if (!isImage && !isPdf)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => _launchUrl(fileUrl),
              tooltip: 'Open',
            ),
          
          // Download button
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: _downloadAndSaveFile,
            tooltip: 'Download',
          ),
          
          // Share button
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: _shareFile,
            tooltip: 'Share',
          ),
        ],
      ),
    );
  }

  // Helper method to get appropriate icon for file type
  IconData _getFileIcon() {
    if (fileContentType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileContentType.contains('word') || fileContentType.contains('doc')) {
      return Icons.description;
    } else if (fileContentType.contains('excel') || fileContentType.contains('sheet')) {
      return Icons.table_chart;
    } else if (fileContentType.contains('text')) {
      return Icons.text_snippet;
    } else if (fileContentType.contains('audio')) {
      return Icons.audio_file;
    } else if (fileContentType.contains('video')) {
      return Icons.video_file;
    } else {
      return Icons.insert_drive_file;
    }
  }

  // Helper method to get color for file icon
  Color _getFileColor() {
    if (fileContentType.contains('pdf')) {
      return Colors.red;
    } else if (fileContentType.contains('word') || fileContentType.contains('doc')) {
      return Colors.blue;
    } else if (fileContentType.contains('excel') || fileContentType.contains('sheet')) {
      return Colors.green;
    } else if (fileContentType.contains('text')) {
      return Colors.orange;
    } else if (fileContentType.contains('audio')) {
      return Colors.purple;
    } else if (fileContentType.contains('video')) {
      return Colors.red.shade700;
    } else {
      return Colors.grey;
    }
  }

  // Format file size for display
  String _formatFileSize() {
    final fileSizeBytes = widget.message.file!['fileSize'] ?? 0;
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Method to launch URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  // Method to download file for viewing
  Future<String> _downloadFile() async {
    final url = Uri.parse(fileUrl);
    final response = await http.get(url);
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    await File(filePath).writeAsBytes(response.bodyBytes);
    return filePath;
  }

  // Method to download and save file to device
  Future<void> _downloadAndSaveFile() async {
    try {
      setState(() => _isLoading = true);
      
      if (kIsWeb) {
        // For web, just open the URL in a new tab
        await _launchUrl(fileUrl);
        setState(() => _isLoading = false);
        return;
      }
      
      // For mobile, check permissions
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Storage permission denied')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
      
      // Generate file path
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      
      // Download file
      final url = Uri.parse(fileUrl);
      final response = await http.get(url);
      
      // Save to temporary location
      await File(filePath).writeAsBytes(response.bodyBytes);
      
      // Use share_plus to save the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Save $fileName',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to share file
  Future<void> _shareFile() async {
    try {
      setState(() => _isLoading = true);
      
      if (kIsWeb) {
        // For web, just copy the URL
        await Clipboard.setData(ClipboardData(text: fileUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File URL copied to clipboard')),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // For mobile, download and share
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      
      // Download file
      final url = Uri.parse(fileUrl);
      final response = await http.get(url);
      
      // Save to temporary location
      await File(filePath).writeAsBytes(response.bodyBytes);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Sharing $fileName',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to open the full viewer
  void _openFullViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(fileName)),
          body: MessageFileViewer(message: widget.message),
        ),
      ),
    );
  }
}