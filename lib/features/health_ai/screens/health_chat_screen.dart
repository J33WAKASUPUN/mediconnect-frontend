// lib/features/health_ai/screens/health_chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/health_ai/providers/health_ai_provider.dart';
import 'package:mediconnect/features/health_ai/widgets/ai_image_uploader.dart';
import 'package:mediconnect/features/health_ai/widgets/ai_message_bubble.dart';
import 'package:mediconnect/features/messages/widgets/web_file_uploader.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:mediconnect/shared/constants/styles.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:mediconnect/config/api_endpoints.dart';

class HealthChatScreen extends StatefulWidget {
  final String sessionId;
  final String? initialMessage;

  const HealthChatScreen({
    Key? key,
    required this.sessionId,
    this.initialMessage,
  }) : super(key: key);

  @override
  State<HealthChatScreen> createState() => _HealthChatScreenState();
}

class _HealthChatScreenState extends State<HealthChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  bool _showEmojiPicker = false;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _focusNode.addListener(_onFocusChange);

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialMessage!;
        Future.delayed(const Duration(milliseconds: 500), _sendMessage);
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _showEmojiPicker = false);
    }
  }

  Future<void> _loadSession() async {
    await Provider.of<HealthAIProvider>(context, listen: false)
        .loadSession(widget.sessionId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<HealthAIProvider>(
          builder: (context, provider, _) {
            final title = provider.currentSession?.title ?? 'Health Assistant';
            return Text(
              title.length > 25 ? '${title.substring(0, 22)}...' : title,
            );
          },
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analyze_image',
                child: Text('Analyze Medical Image'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Conversation'),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'analyze_image':
                  _showImageOptions();
                  break;
                case 'clear':
                  // TODO: Implement clear chat
                  break;
                case 'delete':
                  final confirmed = await _confirmDelete();
                  if (confirmed && context.mounted) {
                    final success = await Provider.of<HealthAIProvider>(context,
                            listen: false)
                        .deleteSession(widget.sessionId);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main chat area
          _buildChatUI(),

          // New message input with emoji picker
          Column(
            children: [
              // Message input - WhatsApp style
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        offset: const Offset(0, -1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Input field with rounded corners and attachments inside
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Emoji button inside field
                              IconButton(
                                icon: Icon(
                                  _showEmojiPicker
                                      ? Icons.keyboard
                                      : Icons.emoji_emotions_outlined,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                onPressed: _toggleEmojiPicker,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),

                              // Text field - no border or highlight when focused
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  focusNode: _focusNode,
                                  maxLines:
                                      5, // Allow multiple lines but cap at 5
                                  minLines: 1, // Start with 1 line
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    border: InputBorder.none, // Remove border
                                    focusedBorder:
                                        InputBorder.none, // Remove focus border
                                    enabledBorder: InputBorder
                                        .none, // Remove enabled border
                                    errorBorder:
                                        InputBorder.none, // Remove error border
                                    disabledBorder: InputBorder
                                        .none, // Remove disabled border
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 10),
                                    hintText: 'Type your health question...',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),

                              // Attachment button inside field
                              IconButton(
                                icon: Icon(
                                  Icons.attach_file,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                onPressed: _showAttachmentOptions,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Send button - slight gap from input field
                      SizedBox(width: 4),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _sendMessage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Emoji picker
              if (_showEmojiPicker)
                SizedBox(
                  height: 300,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      // Get current text and selection
                      final text = _messageController.text;
                      final selection = _messageController.selection;

                      // Insert emoji at current cursor position
                      final newText = selection.textBefore(text) +
                          emoji.emoji +
                          selection.textAfter(text);

                      // Update controller with new text and move cursor after the inserted emoji
                      _messageController.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: selection.baseOffset + emoji.emoji.length,
                        ),
                      );
                    },
                    textEditingController: _messageController,
                    config: Config(
                      height: 280,
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28.0,
                        backgroundColor: Colors.grey[100]!,
                      ),
                      skinToneConfig: SkinToneConfig(
                        indicatorColor: Colors.grey,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        initCategory: Category.RECENT,
                        backgroundColor: Colors.white,
                        iconColorSelected: AppColors.primary,
                        iconColor: Colors.grey,
                        indicatorColor: AppColors.primary,
                        recentTabBehavior: RecentTabBehavior.RECENT,
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        backgroundColor: Colors.white,
                        buttonColor: AppColors.primary,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: Colors.white,
                        buttonIconColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatUI() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/chat_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.7),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Consumer<HealthAIProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSession,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ask a health question',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Type a message below or analyze a medical image',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Scroll to bottom when new messages arrive
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final message = provider.messages[index];
                return AiMessageBubble(
                  message: message,
                  onLinkTap: _handleLinkTap,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _showEmojiPicker = false;
    });

    await Provider.of<HealthAIProvider>(context, listen: false)
        .sendMessage(message);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo, color: AppColors.primary),
              ),
              title:
                  Text('Analyze Medical Image', style: TextStyle(fontSize: 16)),
              subtitle: Text('Upload image for AI analysis',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              onTap: () {
                Navigator.pop(context);
                _showImageOptions();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show an input dialog for the prompt
      final prompt = await _showPromptDialog();
      if (prompt == null || !context.mounted) return;

      // Show loading indicator
      setState(() {
        _isProcessingImage = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // REMOVE THIS LINE:
        // await provider.sendMessage(prompt); // <-- Remove this!

        final provider = Provider.of<HealthAIProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Get the auth token
        final token = authProvider.token ?? '';

        // Create the API URL
        final url =
            '${ApiEndpoints.baseUrl}${ApiEndpoints.healthInsightsAnalyzeImage}';

        // Use our specialized AI image uploader with the session ID
        final result = await AIImageUploader.uploadImageForAnalysis(
          url: url,
          token: token,
          image: pickedFile,
          prompt: prompt,
          sessionId: widget.sessionId,
        );

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }

        if (result['success'] == true) {
          // Reload the session to get the latest messages including the image analysis
          await provider.loadSession(widget.sessionId);
        } else {
          // Show error
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Failed to analyze image: ${result['message'] ?? "Unknown error"}')),
            );
          }
        }
      } catch (e) {
        // Close loading dialog and show error
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error analyzing image: $e')),
          );
        }
      } finally {
        setState(() {
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  // Show a prompt dialog for the image analysis
  Future<String?> _showPromptDialog() {
    final promptController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analyze Medical Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What would you like to know about this image?'),
            SizedBox(height: 16),
            TextField(
              controller: promptController,
              decoration: InputDecoration(
                hintText: 'E.g., What does this skin condition indicate?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = promptController.text.trim();
              Navigator.pop(context,
                  text.isNotEmpty ? text : 'Please analyze this medical image');
            },
            child: Text('ANALYZE'),
          ),
        ],
      ),
    );
  }

  void _handleLinkTap(String? url) {
    if (url != null) {
      launchUrl(Uri.parse(url));
    }
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text(
                'Are you sure you want to delete this conversation? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
