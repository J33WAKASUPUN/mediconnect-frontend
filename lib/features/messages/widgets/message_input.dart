import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class MessageInput extends StatefulWidget {
  final Message? message;
  final Message? replyToMessage;
  final Map<String, dynamic> otherUser;
  final Function(String) onSend;
  final Function() onAttach;
  final Function(bool) onTypingStatusChanged;
  final Function() onCancelEdit;
  final Function()? onCancelReply;

  const MessageInput({
    super.key,
    this.message,
    this.replyToMessage,
    required this.otherUser,
    required this.onSend,
    required this.onAttach,
    required this.onTypingStatusChanged,
    required this.onCancelEdit,
    this.onCancelReply,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _isTyping = false;
  Timer? _typingTimer;
  static const Color primary = Color.fromARGB(255, 66, 68, 214);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message && widget.message != null) {
      _controller.text = widget.message!.content ?? '';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _focusNode.requestFocus();
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _showEmojiPicker = false);
    }
  }

  void _onTextChanged() {
    // Handle typing status
    if (_controller.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTypingStatusChanged(true);
    } else if (_controller.text.isEmpty && _isTyping) {
      _isTyping = false;
      widget.onTypingStatusChanged(false);
    }

    // Reset typing timer
    if (_typingTimer?.isActive ?? false) {
      _typingTimer!.cancel();
    }

    // Set timer to reset typing status after 5 seconds of inactivity
    _typingTimer = Timer(Duration(seconds: 5), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingStatusChanged(false);
      }
    });
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


  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    widget.onSend(_controller.text.trim());
    _controller.clear();
    _isTyping = false;
    widget.onTypingStatusChanged(false);

    if (_typingTimer?.isActive ?? false) {
      _typingTimer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show edit header
        if (widget.message != null) _buildEditingHeader(),

        // Show reply header
        if (widget.replyToMessage != null) _buildReplyHeader(),

        // Message input - WhatsApp style
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
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
                            color: primary,
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
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: 5, // Allow multiple lines but cap at 5
                            minLines: 1, // Start with 1 line
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              border: InputBorder.none, // Remove border
                              focusedBorder: InputBorder.none, // Remove focus border
                              enabledBorder: InputBorder.none, // Remove enabled border
                              errorBorder: InputBorder.none, // Remove error border
                              disabledBorder: InputBorder.none, // Remove disabled border
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                              hintText: widget.message != null
                                  ? 'Edit message'
                                  : widget.replyToMessage != null
                                      ? 'Reply to message'
                                      : 'Message',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                        
                        // Attachment button inside field
                        IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: primary,
                            size: 24,
                          ),
                          onPressed: widget.onAttach,
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
                    color: primary,
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
                      widget.message != null ? Icons.check : Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _handleSend,
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
                final text = _controller.text;
                final selection = _controller.selection;
                
                // Insert emoji at current cursor position
                final newText = selection.textBefore(text) + emoji.emoji + selection.textAfter(text);
                
                // Update controller with new text and move cursor after the inserted emoji
                _controller.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(
                    offset: selection.baseOffset + emoji.emoji.length,
                  ),
                );
              },
              textEditingController: _controller,
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
                  iconColorSelected: primary,
                  iconColor: Colors.grey,
                  indicatorColor: primary,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: Colors.white,
                  buttonColor: primary,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Colors.white,
                  buttonIconColor: primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyHeader() {
    final message = widget.replyToMessage!;
    final isTextMessage = message.messageType == 'text';
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = message.senderId == authProvider.user?.id;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.only(bottom: 4, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 3,
            height: 36,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.green,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reply to ${isCurrentUser ? 'yourself' : widget.otherUser['firstName']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.blue : Colors.green,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                if (isTextMessage)
                  Text(
                    message.content ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(
                        message.messageType == 'image'
                            ? Icons.image
                            : Icons.insert_drive_file,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        message.messageType == 'image'
                            ? 'Photo'
                            : 'Document',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            constraints: BoxConstraints(),
            padding: EdgeInsets.all(4),
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditingHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.only(bottom: 4, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 3,
            height: 36,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing Message',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.message?.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            constraints: BoxConstraints(),
            padding: EdgeInsets.all(4),
            onPressed: widget.onCancelEdit,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}