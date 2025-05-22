import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class MessageFileWidget extends StatelessWidget {
  final String fileUrl;
  final String contentType;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const MessageFileWidget({
    Key? key,
    required this.fileUrl,
    required this.contentType,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  bool get isImage => contentType.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    if (isImage) {
      return _buildImageWidget();
    } else {
      return _buildDocumentWidget(context);
    }
  }

  Widget _buildImageWidget() {
    return Container(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: fileUrl,
        fit: fit,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(height: 4),
              Text(
                'Error loading image',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentWidget(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    if (contentType.contains('pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (contentType.contains('word') || contentType.contains('doc')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (contentType.contains('excel') || contentType.contains('sheet')) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else if (contentType.contains('text') || contentType.contains('plain')) {
      iconData = Icons.text_snippet;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 40,
            color: iconColor,
          ),
          SizedBox(height: 8),
          Text(
            fileUrl.split('/').last,
            style: TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}