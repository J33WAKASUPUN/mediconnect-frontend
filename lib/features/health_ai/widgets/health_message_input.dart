import 'package:flutter/material.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class HealthMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function() onSend;
  final Function() onAttach;

  const HealthMessageInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
  }) : super(key: key);

  @override
  _HealthMessageInputState createState() => _HealthMessageInputState();
}

class _HealthMessageInputState extends State<HealthMessageInput> {
  bool _showEmojiPicker = false;

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        widget.focusNode.unfocus();
      } else {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                            controller: widget.controller,
                            focusNode: widget.focusNode,
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
                              hintText: 'Type your health question...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                        
                        // Attachment button inside field
                        IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: AppColors.primary,
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
                    onPressed: widget.onSend,
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
                final text = widget.controller.text;
                final selection = widget.controller.selection;
                
                // Insert emoji at current cursor position
                final newText = selection.textBefore(text) + emoji.emoji + selection.textAfter(text);
                
                // Update controller with new text and move cursor after the inserted emoji
                widget.controller.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(
                    offset: selection.baseOffset + emoji.emoji.length,
                  ),
                );
              },
              textEditingController: widget.controller,
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
    );
  }
}