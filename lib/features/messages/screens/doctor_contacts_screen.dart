import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/conversation.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/user_service.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/provider/conversation_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_detail_screen.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:mediconnect/shared/constants/styles.dart';
import 'package:provider/provider.dart';

class DoctorContactsScreen extends StatefulWidget {
  const DoctorContactsScreen({super.key});

  @override
  _DoctorContactsScreenState createState() => _DoctorContactsScreenState();
}

class _DoctorContactsScreenState extends State<DoctorContactsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();

  // Lists for each tab
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  List<Map<String, dynamic>> _myPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final conversationProvider =
          Provider.of<ConversationProvider>(context, listen: false);

      // Set token if available
      if (authProvider.isAuthenticated && authProvider.token != null) {
        userService.setAuthToken(authProvider.token!);
      }

      // Make sure conversations are loaded
      await conversationProvider.loadConversations();

      // Get doctors list
      final doctors = await userService.getAllDoctors();

      // Filter out the current doctor
      final otherDoctors = doctors.where((doctor) {
        final doctorId = doctor['_id'] ?? doctor['id'];
        return doctorId != authProvider.user?.id;
      }).toList();

      // Get patients who have messaged this doctor
      final List<Map<String, dynamic>> patients = [];

      // Extract patients from conversations
      for (var conversation in conversationProvider.conversations) {
        final participant = conversation.participant;
        if (participant != null &&
            (participant['role'] == 'patient' ||
                participant['role'] == 'Patient')) {
          // Check if not already in list
          final participantId = participant['_id'] ?? participant['id'];
          if (!patients.any((p) => (p['_id'] ?? p['id']) == participantId)) {
            patients.add(participant);
          }
        }
      }

      setState(() {
        _allDoctors = otherDoctors;
        _filteredDoctors = otherDoctors;
        _myPatients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      print('Error loading contacts: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contacts: $e')),
      );
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _searchQuery = query;

      // Filter doctors
      if (query.isEmpty) {
        _filteredDoctors = _allDoctors;
      } else {
        _filteredDoctors = _allDoctors.where((doctor) {
          final firstName = doctor['firstName'] ?? '';
          final lastName = doctor['lastName'] ?? '';
          final specialty = doctor['specialty'] ?? '';
          final fullName = '$firstName $lastName'.toLowerCase();

          return fullName.contains(query) ||
              specialty.toLowerCase().contains(query);
        }).toList();
      }

      // Filter patients
      if (query.isEmpty) {
        _filteredPatients = _myPatients;
      } else {
        _filteredPatients = _myPatients.where((patient) {
          final firstName = patient['firstName'] ?? '';
          final lastName = patient['lastName'] ?? '';
          final fullName = '$firstName $lastName'.toLowerCase();

          return fullName.contains(query);
        }).toList();
      }
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

      // Reset filtered lists
      _filteredDoctors = _allDoctors;
      _filteredPatients = _myPatients;
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: AppColors.primary),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search contacts...',
                    hintStyle:
                        TextStyle(color: AppColors.primary.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close, color: AppColors.primary),
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
                    onPressed: () {
                      _loadData();
                    },
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [
                Tab(text: "Doctors"),
                Tab(text: "Patients"),
              ],
            ),
          ),

          // My Contacts header with Search button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Contacts',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _startSearch,
                  icon: Icon(Icons.search, size: 18),
                  label: Text('Search contacts'),
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

          if (_error != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Error: $_error',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: AppStyles.primaryButton,
                    onPressed: _loadData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Doctors Tab
                      _buildContactList(_filteredDoctors, isDoctor: true),

                      // Patients Tab
                      _buildContactList(_filteredPatients, isDoctor: false),
                    ],
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

  Widget _buildContactList(List<Map<String, dynamic>> contacts,
      {required bool isDoctor}) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No ${isDoctor ? "doctors" : "patients"} available'
                  : 'No ${isDoctor ? "doctors" : "patients"} match your search',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: _loadData,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: Scrollbar(
        controller: _scrollController,
        thickness: 6,
        radius: const Radius.circular(3),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: contacts.length,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final contactId = contact['_id'] ?? contact['id'];

            if (contactId == null) {
              return SizedBox.shrink(); // Skip if no ID
            }

            final firstName = contact['firstName'] ?? '';
            final lastName = contact['lastName'] ?? '';
            final specialty =
                isDoctor ? (contact['specialty'] ?? 'Doctor') : '';
            final role = !isDoctor ? (contact['role'] ?? 'Patient') : '';

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 1),
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
                  onTap: () => _startConversation(contact),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        // Avatar with border
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary, width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: contact['profilePicture'] != null
                                ? NetworkImage(contact['profilePicture'])
                                : null,
                            child: contact['profilePicture'] == null
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDoctor
                                    ? 'Dr. $firstName $lastName'
                                    : '$firstName $lastName',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                isDoctor ? specialty : role,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
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
  }

  void _startConversation(Map<String, dynamic> contact) async {
    try {
      final messageService =
          Provider.of<MessageService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Ensure MessageService has the auth token
      if (authProvider.isAuthenticated && authProvider.token != null) {
        messageService.setAuthToken(authProvider.token!);
      }

      final contactId = contact['_id'] ?? contact['id'];
      if (contactId == null) {
        throw Exception('Contact ID is missing');
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Check if a conversation already exists
      final conversationProvider =
          Provider.of<ConversationProvider>(context, listen: false);
      final existingConversation =
          conversationProvider.conversations.firstWhere(
        (c) =>
            c.participant != null &&
            ((c.participant['_id'] ?? c.participant['id']) == contactId),
        orElse: () => Conversation(
          id: '',
          participant: {},
          lastMessage: {},
          updatedAt: DateTime.now(),
          metadata: {},
          unreadCount: 0,
        ),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (existingConversation.id.isNotEmpty) {
        // Navigate to existing conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: existingConversation.id,
              otherUser: contact,
            ),
          ),
        );
      } else {
        // Send initial message to create conversation
        final isDoctor =
            contact['role'] == 'doctor' || contact['role'] == 'Doctor';
        final greeting = isDoctor
            ? 'Hello Dr. ${contact['firstName']}'
            : 'Hello ${contact['firstName']}';

        final response = await messageService.sendMessage(
          receiverId: contactId,
          content: greeting,
        );

        if (response['success'] == true && response['data'] != null) {
          final message = Message.fromJson(response['data']);

          // Navigate to chat detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                conversationId: message.conversationId,
                otherUser: contact,
              ),
            ),
          );
        } else {
          throw Exception(
              'Failed to create conversation: ${response['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start conversation: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
