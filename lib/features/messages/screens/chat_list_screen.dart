import 'package:flutter/material.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/provider/conversation_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_detail_screen.dart';
import 'package:mediconnect/features/messages/screens/doctor_selection_screen.dart';
import 'package:mediconnect/features/messages/widgets/conversation_tile.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    await conversationProvider.loadConversations();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _showDoctorSelectionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final conversationProvider = Provider.of<ConversationProvider>(context);
    final currentUser = authProvider.user;
    final isPatient = currentUser?.role == 'patient';

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search conversations',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text('Messages'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: conversationProvider.isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildConversationList(conversationProvider),
      ),
      floatingActionButton: isPatient
          ? FloatingActionButton(
              onPressed: _showDoctorSelectionScreen,
              child: Icon(Icons.add),
              tooltip: 'Start new conversation with a doctor',
            )
          : null,
    );
  }

  Widget _buildConversationList(ConversationProvider provider) {
    final conversations = _searchQuery.isEmpty
        ? provider.conversations
        : provider.searchConversations(_searchQuery);

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start a new conversation by tapping the + button',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Find the other participant
        final otherParticipant = conversation.participants.firstWhere(
          (p) => p['_id'] != authProvider.user!.id,
          orElse: () => {},
        );
        
        if (otherParticipant.isEmpty) return SizedBox.shrink();
        
        return ConversationTile(
          conversation: conversation,
          otherUser: otherParticipant,
          onTap: () {
            // Reset unread count
            provider.resetUnreadCount(conversation.id);
            
            // Navigate to chat detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  conversationId: conversation.id,
                  otherUser: otherParticipant,
                ),
              ),
            );
          },
        );
      },
    );
  }
}