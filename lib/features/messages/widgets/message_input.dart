import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

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

        // Message input
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, -1),
                blurRadius: 5,
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: widget.onAttach,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showEmojiPicker
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _toggleEmojiPicker,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: widget.message != null
                                ? 'Edit message'
                                : widget.replyToMessage != null
                                    ? 'Reply to message'
                                    : 'Type a message',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 24,
                child: IconButton(
                  icon: Icon(
                    widget.message != null ? Icons.check : Icons.send,
                    color: Colors.white,
                  ),
                  onPressed: _handleSend,
                ),
              ),
            ],
          ),
        ),
        
        // Emoji picker
        if (_showEmojiPicker)
          SizedBox(
            height: 350,
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
                height: 150,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 25.0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                skinToneConfig: SkinToneConfig(
                  indicatorColor: Colors.grey,
                ),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.RECENT,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  iconColorSelected: Theme.of(context).primaryColor,
                  iconColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  recentTabBehavior: RecentTabBehavior.RECENT,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  buttonColor: Theme.of(context).primaryColor,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  buttonIconColor: Theme.of(context).primaryColor,
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
      padding: EdgeInsets.all(8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontSize: 14,
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
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        message.messageType == 'image'
                            ? 'Photo'
                            : 'Document',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
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
      padding: EdgeInsets.all(8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing Message',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  widget.message?.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close),
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