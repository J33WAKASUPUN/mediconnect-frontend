import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mediconnect/core/models/health_ai_model.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:mediconnect/shared/constants/styles.dart';

class AiMessageBubble extends StatelessWidget {
  final HealthMessage message;
  final Function(String?)? onLinkTap;
  
  const AiMessageBubble({
    Key? key,
    required this.message,
    this.onLinkTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';
    final isLoading = message.isLoading;
    final isError = message.isError;
    
    // For loading message
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(context, isUser, isSystem),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, isUser, isSystem),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBubbleColor(isUser, isSystem, isError),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 0),
                  topRight: Radius.circular(isUser ? 0 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: _buildMessageContent(context, isUser, isSystem),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(context, isUser, isSystem),
        ],
      ),
    );
  }
  
  Widget _buildAvatar(BuildContext context, bool isUser, bool isSystem) {
    IconData iconData;
    Color bgColor;
    Color iconColor;
    
    if (isUser) {
      iconData = Icons.person;
      bgColor = AppColors.primary;
      iconColor = AppColors.textLight;
    } else if (isSystem) {
      iconData = Icons.info_outline;
      bgColor = AppColors.warning;
      iconColor = AppColors.textLight;
    } else {
      iconData = Icons.health_and_safety;
      bgColor = AppColors.secondary;
      iconColor = AppColors.textLight;
    }
    
    return CircleAvatar(
      radius: 16,
      backgroundColor: bgColor,
      child: Icon(iconData, color: iconColor, size: 16),
    );
  }
  
  Widget _buildMessageContent(BuildContext context, bool isUser, bool isSystem) {
    final textColor = isUser ? AppColors.textLight : AppColors.textPrimary;
    
    // Create text styles based on your AppStyles but with the needed colors
    final bodyTextStyle = TextStyle(
      fontSize: AppStyles.bodyText2.fontSize,
      fontWeight: AppStyles.bodyText2.fontWeight,
      color: textColor,
    );
    
    final headingStyle = TextStyle(
      fontSize: AppStyles.heading2.fontSize,
      fontWeight: AppStyles.heading2.fontWeight,
      color: textColor,
    );

    final heading3Style = TextStyle(
      fontSize: 16, // Since AppStyles.heading3 is not defined, use 16
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    
    final captionStyle = TextStyle(
      fontSize: AppStyles.caption.fontSize,
      fontWeight: AppStyles.caption.fontWeight,
      color: textColor.withOpacity(0.7),
    );
    
    // Check for image content - markdown content may include images
    if (message.content.contains("![") && message.content.contains("](") && !isUser) {
      // Extract image URLs from markdown: ![alt](url)
      final regExp = RegExp(r'!\[(.*?)\]\((.*?)\)');
      final matches = regExp.allMatches(message.content);
      
      if (matches.isNotEmpty) {
        final imageUrls = <String>[];
        String textContent = message.content;
        
        // Extract image URLs and remove image markdown from text content
        for (final match in matches) {
          final url = match.group(2)!;
          imageUrls.add(url);
          textContent = textContent.replaceAll(match.group(0)!, '');
        }
        
        // Build a column with images and text
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the images
            ...imageUrls.map((url) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, e, stackTrace) {
                    return Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: AppColors.error),
                    );
                  },
                ),
              ),
            )),
            
            // Display the text content
            if (textContent.trim().isNotEmpty)
              MarkdownBody(
                data: textContent.trim(),
                selectable: true,
                onTapLink: (text, href, title) {
                  if (onLinkTap != null) onLinkTap!(href);
                },
                styleSheet: MarkdownStyleSheet(
                  p: bodyTextStyle,
                  a: TextStyle(
                    fontSize: AppStyles.bodyText2.fontSize,
                    color: isUser ? AppColors.textLight.withOpacity(0.9) : AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  strong: TextStyle(
                    fontSize: AppStyles.bodyText2.fontSize,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: isUser 
                        ? AppColors.primary.withOpacity(0.3) 
                        : AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: const Border(
                      left: BorderSide(color: AppColors.border, width: 4),
                    ),
                  ),
                  blockquote: TextStyle(
                    fontSize: AppStyles.bodyText2.fontSize,
                    color: textColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  code: TextStyle(
                    fontSize: AppStyles.bodyText2.fontSize,
                    color: textColor,
                    backgroundColor: isUser 
                        ? AppColors.primary.withOpacity(0.3) 
                        : AppColors.background,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isUser 
                        ? AppColors.primary.withOpacity(0.3) 
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  h1: headingStyle,
                  h2: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  h3: heading3Style,
                  listBullet: bodyTextStyle,
                ),
              ),
          ],
        );
      }
    }
    
    // Default case - no images, just text
    return MarkdownBody(
      data: message.content,
      selectable: true,
      onTapLink: (text, href, title) {
        if (onLinkTap != null) onLinkTap!(href);
      },
      styleSheet: MarkdownStyleSheet(
        p: bodyTextStyle,
        a: TextStyle(
          fontSize: AppStyles.bodyText2.fontSize,
          color: isUser ? AppColors.textLight.withOpacity(0.9) : AppColors.primary,
          decoration: TextDecoration.underline,
        ),
        strong: TextStyle(
          fontSize: AppStyles.bodyText2.fontSize,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        blockquoteDecoration: BoxDecoration(
          color: isUser 
              ? AppColors.primary.withOpacity(0.3) 
              : AppColors.background.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
          border: const Border(
            left: BorderSide(color: AppColors.border, width: 4),
          ),
        ),
        blockquote: TextStyle(
          fontSize: AppStyles.bodyText2.fontSize,
          color: textColor.withOpacity(0.8),
          fontStyle: FontStyle.italic,
        ),
        code: TextStyle(
          fontSize: AppStyles.bodyText2.fontSize,
          color: textColor,
          backgroundColor: isUser 
              ? AppColors.primary.withOpacity(0.3) 
              : AppColors.background,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: isUser 
              ? AppColors.primary.withOpacity(0.3) 
              : AppColors.background,
          borderRadius: BorderRadius.circular(4),
        ),
        h1: headingStyle,
        h2: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h3: heading3Style,
        listBullet: bodyTextStyle,
      ),
    );
  }
  
  Color _getBubbleColor(bool isUser, bool isSystem, bool isError) {
    if (isError) return AppColors.error.withOpacity(0.1);
    if (isUser) return AppColors.primary;
    if (isSystem) return AppColors.warning.withOpacity(0.1);
    return AppColors.surface; // Changed from background to surface for better contrast
  }
}