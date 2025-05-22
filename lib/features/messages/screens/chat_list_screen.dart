import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/conversation.dart';
import 'package:mediconnect/features/messages/provider/conversation_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_detail_screen.dart';
import 'package:mediconnect/core/services/auth_service.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:mediconnect/shared/constants/styles.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    try {
      await Provider.of<ConversationProvider>(context, listen: false)
          .loadConversations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  Future<void> _refreshConversations() async {
    try {
      setState(() {
        _isRefreshing = true;
      });

      await Provider.of<ConversationProvider>(context, listen: false)
          .loadConversations();

      setState(() {
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing conversations: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      // Request focus to automatically show keyboard
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, // White background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style:
                      TextStyle(color: AppColors.primary), // Primary color text
                  cursorColor: AppColors.primary, // Primary color cursor
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(
                        color: AppColors.primary
                            .withOpacity(0.7)), // Primary color placeholder
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.primary), // Primary color icon
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close,
                          color: AppColors.primary), // Primary color close icon
                      onPressed: _stopSearch,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            : Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'MediConnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _isRefreshing ? null : _refreshConversations,
                  ),
                ],
              ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Search Button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chats',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _startSearch,
                  icon: Icon(Icons.search, size: 18),
                  label: Text('Search chats'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }

                if (provider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearErrors();
                            _loadConversations();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter conversations based on search
                List<Conversation> filteredConversations = _searchQuery.isEmpty
                    ? provider.conversations
                    : provider.searchConversations(_searchQuery);

                if (filteredConversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No conversations yet'
                              : 'No matches found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty) SizedBox(height: 24),
                        if (_searchQuery.isEmpty)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, '/messages/doctor-selection');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text('Start new conversation'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshConversations,
                  child: Scrollbar(
                    controller: _scrollController,
                    thickness: 6,
                    radius: const Radius.circular(3),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredConversations.length,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final conversation = filteredConversations[index];

                        // Get the other participant
                        final authService =
                            Provider.of<AuthService>(context, listen: false);
                        final currentUserId = authService.currentUserId;

                        // Safety check for currentUserId
                        if (currentUserId == null) {
                          return SizedBox.shrink();
                        }

                        final otherParticipant = _findOtherParticipant(
                          conversation.participant,
                          currentUserId,
                        );

                        if (otherParticipant == null) {
                          return SizedBox.shrink();
                        }

                        final firstName = otherParticipant['firstName'] ?? '';
                        final lastName = otherParticipant['lastName'] ?? '';
                        final profilePicture =
                            otherParticipant['profilePicture'];
                        final role = otherParticipant['role'] ?? '';
                        final isDoctor = role.toLowerCase() == 'doctor';

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailScreen(
                                      conversationId: conversation.id,
                                      otherUser: otherParticipant,
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh data when returning from chat
                                  _loadConversations();
                                });

                                // Reset unread count
                                if (conversation.unreadCount > 0) {
                                  provider.resetUnreadCount(conversation.id);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    // Avatar with border
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.primary,
                                            width: 1.5),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            AppColors.primary.withOpacity(0.1),
                                        backgroundImage: profilePicture != null
                                            ? NetworkImage(profilePicture)
                                            : null,
                                        child: profilePicture == null
                                            ? Text(
                                                firstName.isNotEmpty
                                                    ? firstName[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  isDoctor
                                                      ? 'Dr. $firstName $lastName'
                                                      : '$firstName $lastName',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                _formatTimestamp(
                                                    conversation.updatedAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _getLastMessageText(
                                                      conversation),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                    fontWeight: conversation
                                                                .unreadCount >
                                                            0
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              if (conversation.unreadCount > 0)
                                                Container(
                                                  margin:
                                                      EdgeInsets.only(left: 8),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    conversation.unreadCount
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/messages/doctor-selection');
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16), // Square with rounded corners
          ),
          child: Icon(
            Icons.edit_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Helper to find the other participant in a conversation
  Map<String, dynamic>? _findOtherParticipant(
      dynamic participant, String currentUserId) {
    try {
      // If participant is already a Map, just return it
      if (participant is Map) {
        return Map<String, dynamic>.from(participant);
      }

      // If it's a List, find the other participant
      if (participant is List) {
        return participant.firstWhere(
          (p) => p['_id'] != currentUserId,
          orElse: () => null,
        );
      }

      return null;
    } catch (e) {
      print('Error finding other participant: $e');
      return null;
    }
  }

  // Helper to get the last message text
  String _getLastMessageText(Conversation conversation) {
    if (conversation.lastMessage == null) {
      return 'Tap to start conversation';
    }

    if (conversation.lastMessage is Map) {
      return conversation.lastMessage['content'] ?? 'New message';
    }

    // Handle other types
    return 'New message';
  }

  // Helper to format timestamp like Whispr
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    // Format like your original app
    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year.toString().substring(2)}';
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
