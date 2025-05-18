import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/user_service.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_detail_screen.dart';
import 'package:provider/provider.dart';

class DoctorSelectionScreen extends StatefulWidget {
  @override
  _DoctorSelectionScreenState createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get UserService from Provider
      final userService = Provider.of<UserService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Set token if available
      if (authProvider.isAuthenticated && authProvider.token != null) {
        userService.setAuthToken(authProvider.token!);
      }

      List<Map<String, dynamic>> doctors = [];

      if (authProvider.user != null) {
        final patientId = authProvider.user!.id;
        doctors = await userService.getDoctorsForPatient(patientId);

        if (doctors.isEmpty) {
          doctors = await userService.getAllDoctors();
        }
      } else {
        doctors = await userService.getAllDoctors();
      }

      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      print('Error loading doctors: $e');

      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctors: $e')),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterDoctors();
    });
  }

  void _filterDoctors() {
    if (_searchQuery.isEmpty) {
      _filteredDoctors = _doctors;
    } else {
      _filteredDoctors = _doctors.where((doctor) {
        final firstName = doctor['firstName'] ?? '';
        final lastName = doctor['lastName'] ?? '';
        final specialty = doctor['specialty'] ?? '';

        final fullName = '$firstName $lastName'.toLowerCase();
        final query = _searchQuery.toLowerCase();

        return fullName.contains(query) ||
            specialty.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Doctor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                    onPressed: _loadDoctors,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildDoctorList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No doctors available'
                  : 'No doctors match your search',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDoctors,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredDoctors.length,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final doctor = _filteredDoctors[index];
        final doctorId = doctor['_id'] ?? doctor['id'];

        if (doctorId == null) {
          return SizedBox.shrink(); // Skip if no ID
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _startConversation(doctor),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: doctor['profilePicture'] != null
                        ? NetworkImage(doctor['profilePicture'])
                        : null,
                    child: doctor['profilePicture'] == null
                        ? Text(
                            '${doctor['firstName']?[0] ?? ''}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          doctor['specialty'] ?? 'Doctor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startConversation(Map<String, dynamic> doctor) async {
    try {
      final messageService =
          Provider.of<MessageService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Ensure MessageService has the auth token
      if (authProvider.isAuthenticated && authProvider.token != null) {
        messageService.setAuthToken(authProvider.token!);
      }

      final doctorId = doctor['_id'] ?? doctor['id'];
      if (doctorId == null) {
        throw Exception('Doctor ID is missing');
      }

      // Send initial message to create conversation
      final response = await messageService.sendMessage(
        receiverId: doctorId,
        content: 'Hello Dr. ${doctor['firstName']}',
      );

      if (response['success'] == true && response['data'] != null) {
        final message = Message.fromJson(response['data']);

        // Navigate to chat detail
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: message.conversationId,
              otherUser: doctor,
            ),
          ),
        );
      } else {
        throw Exception(
            'Failed to create conversation: ${response['message'] ?? 'Unknown error'}');
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
    super.dispose();
  }
}
