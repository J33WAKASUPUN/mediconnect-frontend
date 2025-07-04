import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/message.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/user_service.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_detail_screen.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:mediconnect/shared/constants/styles.dart';
import 'package:provider/provider.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  _DoctorSelectionScreenState createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();

  // For doctor categories
  List<String?> _specialties = [];
  String? _selectedSpecialty;

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

      // Extract unique specialties
      Set<String?> uniqueSpecialties = doctors
          .map((d) => d['specialty'] as String?)
          .where((s) => s != null && s.isNotEmpty)
          .toSet();

      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _specialties = uniqueSpecialties.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      print('Error loading doctors: $e');

      // Show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterDoctors();
    });
  }

  void _filterDoctors() {
    List<Map<String, dynamic>> filtered = _doctors;

    // Apply specialty filter
    if (_selectedSpecialty != null) {
      filtered = filtered.where((doctor) {
        return doctor['specialty'] == _selectedSpecialty;
      }).toList();
    }

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((doctor) {
        final firstName = doctor['firstName'] ?? '';
        final lastName = doctor['lastName'] ?? '';
        final specialty = doctor['specialty'] ?? '';

        final fullName = '$firstName $lastName'.toLowerCase();

        return fullName.contains(query) ||
            specialty.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredDoctors = filtered;
    });
  }

  void _selectSpecialty(String? specialty) {
    setState(() {
      _selectedSpecialty = specialty;
      _filterDoctors();
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
      _filterDoctors();
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
                    hintText: 'Search doctors...',
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
                    onPressed: _loadDoctors,
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          // Section Header with Search Button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Doctor',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _startSearch,
                  icon: Icon(Icons.search, size: 18),
                  label: Text('Search doctors'),
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

          // Specialty filter chips
          if (_specialties.isNotEmpty && !_isSearching)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // "All" chip
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('All'),
                        selected: _selectedSpecialty == null,
                        onSelected: (selected) {
                          if (selected) {
                            _selectSpecialty(null);
                          }
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: _selectedSpecialty == null
                              ? AppColors.primary
                              : Colors.black,
                          fontWeight: _selectedSpecialty == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Specialty chips
                    ..._specialties.map(
                      (specialty) => Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(specialty ?? 'Unknown'),
                          selected: _selectedSpecialty == specialty,
                          onSelected: (selected) {
                            _selectSpecialty(selected ? specialty : null);
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: _selectedSpecialty == specialty
                                ? AppColors.primary
                                : Colors.black,
                            fontWeight: _selectedSpecialty == specialty
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _loadDoctors,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _buildDoctorList(),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {},
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

  Widget _buildDoctorList() {
    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _selectedSpecialty == null
                  ? 'No doctors available'
                  : 'No doctors match your filters',
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
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedSpecialty = null;
                  _searchController.clear();
                  _filteredDoctors = _doctors;
                });
              },
              child: Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await _loadDoctors();
        return Future.value();
      },
      child: Scrollbar(
        controller: _scrollController,
        thickness: 6,
        radius: const Radius.circular(3),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _filteredDoctors.length,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final doctor = _filteredDoctors[index];
            final doctorId = doctor['_id'] ?? doctor['id'];
            final firstName = doctor['firstName'] ?? '';
            final lastName = doctor['lastName'] ?? '';
            final specialty = doctor['specialty'] ?? 'Doctor';

            if (doctorId == null) {
              return SizedBox.shrink(); // Skip if no ID
            }

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
                  onTap: () => _startConversation(doctor),
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
                            backgroundImage: doctor['profilePicture'] != null
                                ? NetworkImage(doctor['profilePicture'])
                                : null,
                            child: doctor['profilePicture'] == null
                                ? Text(
                                    firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
                                        : 'D',
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
                                'Dr. $firstName $lastName',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                specialty,
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

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Send initial message to create conversation
      final response = await messageService.sendMessage(
        receiverId: doctorId,
        content: 'Hello Dr. ${doctor['firstName']}',
      );

      // Close loading indicator
      Navigator.pop(context);

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
    _scrollController.dispose();
    super.dispose();
  }
}
