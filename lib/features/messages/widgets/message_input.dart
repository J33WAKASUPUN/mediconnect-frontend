// lib/widgets/messages/message_input.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/features/messages/widgets/emoji_panel.dart';

class MessageInput extends StatefulWidget {
  final Message? message;
  final Function(String) onSend;
  final Function() onAttach;
  final Function(bool) onTypingStatusChanged;
  final Function() onCancelEdit;

  const MessageInput({
    Key? key,
    this.message,
    required this.onSend,
    required this.onAttach,
    required this.onTypingStatusChanged,
    required this.onCancelEdit,
  }) : super(key: key);

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

  void _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final textSelection = _controller.selection;
    final newText = text.replaceRange(
      textSelection.start,
      textSelection.end,
      emoji,
    );
    
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.message != null) _buildEditingHeader(),
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
        if (_showEmojiPicker)
          CustomEmojiPanel(
            onEmojiSelected: _onEmojiSelected,
          ),
      ],
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