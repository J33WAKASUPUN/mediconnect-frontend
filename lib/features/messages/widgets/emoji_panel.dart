import 'package:flutter/material.dart';

class CustomEmojiPanel extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const CustomEmojiPanel({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  State<CustomEmojiPanel> createState() => _CustomEmojiPanelState();
}

class _CustomEmojiPanelState extends State<CustomEmojiPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Emoji categories with their respective emojis and icons
  static final Map<IconData, Map<String, List<String>>> emojiCategories = {
    Icons.history: {
      '': [
        // Smileys & Emotions
        '😊', '😂', '😍', '😎', '😭', '😡', '😱', '🤔', '😴', '😇',

        // Hand Gestures
        '👍', '👏', '🙏', '🙌', '🤙', '👌', '🤝', '👊', '✌️', '🤞',

        // Hearts & Symbols
        '❤️', '💔', '💖', '💙', '💜', '🖤', '💯', '✔️', '❌', '⚡',

        // Animals & Nature
        '🐶', '🐱', '🦁', '🐼', '🐸', '🌸', '🌞', '🌈', '🔥', '🌍'
      ],
    },
    Icons.sentiment_satisfied: {
      'Faces': [
        '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
        '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳',
      ],
      'Emotions': [
        '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭',
        '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔',
      ],
    },
    Icons.pets: {
      'Animals': [
        '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵',
        '🐔', '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋',
      ],
      'Nature': [
        '🌸', '💐', '🌷', '🌹', '🥀', '🌺', '🌸', '🌼', '🌻', '🌞', '🌝', '🌛', '🌜', '🌚', '🌕',
        '🌖', '🌗', '🌘', '🌑', '🌒', '🌓', '🌔', '🌙', '🌎', '🌍', '🌏', '🪐', '💫', '⭐️', '🌟',
      ],
    },
    Icons.favorite: {
      'Hearts': [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗',
        '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: emojiCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCategorySelector(),
          Expanded(child: _buildEmojiGrid()),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 2,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        tabs: emojiCategories.keys.map((icon) {
          return Tab(
            icon: Icon(
              icon,
              size: 24,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return TabBarView(
      controller: _tabController,
      children: emojiCategories.entries.map((category) {
        return ListView(
          children: category.value.entries.map((subcategory) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subcategory.key.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      subcategory.key,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: subcategory.value.length,
                  itemBuilder: (context, index) {
                    return _buildEmojiButton(subcategory.value[index]);
                  },
                ),
              ],
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return InkWell(
      onTap: () => widget.onEmojiSelected(emoji),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}