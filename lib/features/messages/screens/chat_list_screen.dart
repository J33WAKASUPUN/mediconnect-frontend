import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/conversation.dart';
import 'package:mediconnect/features/messages/provider/conversation_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_detail_screen.dart';
import 'package:mediconnect/core/services/auth_service.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(_isRefreshing ? Icons.sync_disabled : Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (provider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${provider.errorMessage}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearErrors();
                            _loadConversations();
                          },
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
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No conversations yet'
                              : 'No conversations match your search',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                                context, '/messages/doctor-selection');
                          },
                          child: Text('Start new conversation'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshConversations,
                  child: ListView.builder(
                    itemCount: filteredConversations.length,
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
                      final profilePicture = otherParticipant['profilePicture'];

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profilePicture != null
                                ? NetworkImage(profilePicture)
                                : null,
                            child: profilePicture == null
                                ? Text(
                                    firstName.isNotEmpty ? firstName[0] : '?')
                                : null,
                          ),
                          title: Text('$firstName $lastName'),
                          subtitle: Text(
                            _getLastMessageText(conversation),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTimestamp(conversation.updatedAt),
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              SizedBox(height: 4),
                              if (conversation.unreadCount > 0)
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    conversation.unreadCount.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/messages/doctor-selection');
        },
        child: Icon(Icons.chat),
        tooltip: 'New conversation',
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
      return 'No messages yet';
    }

    if (conversation.lastMessage is Map) {
      return conversation.lastMessage['content'] ?? 'New message';
    }

    // Handle other types
    return 'New message';
  }

  // Helper to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
