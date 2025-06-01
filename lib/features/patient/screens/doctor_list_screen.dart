import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/doctor_list_provider.dart';
import '../widgets/doctor_card.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _specialties = [
    'All',
    'Cardiologist',
    'Neurologist',
    'Pediatrician',
    'General Physician',
    'Orthopedic Surgeon',
    'Dermatologist',
    'Ophthalmologist',
    'Otolaryngologist (ENT Specialist)',
    'Psychiatrist',
    'Pulmonologist',
    'Nephrologist',
    'Gastroenterologist',
    'Endocrinologist',
    'Oncologist',
    'Gynecologist',
    'Obstetrician',
    'Hematologist',
    'Urologist',
    'Infectious Disease Specialist',
    'Allergist / Immunologist',
    'Physiatrist (Rehabilitation Specialist)',
    'Emergency Medicine Specialist',
    'Anesthesiologist',
    'Pathologist',
    'Radiologist',
    'Geriatrician',
    'Pain Management Specialist'
  ];

  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  // Colors matching your dashboard
  static const Color primaryColor = Color(0xFF4D4DFF);

  // Track if search has text for showing clear button
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DoctorListProvider>().loadDoctors());

    // Add listener to detect when text changes to show/hide X button
    _searchController.addListener(() {
      _onSearchChanged();

      // Update the state to show/hide X button
      if (_hasSearchText != (_searchController.text.isNotEmpty)) {
        setState(() {
          _hasSearchText = _searchController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<DoctorListProvider>().setSearchQuery(_searchController.text);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<DoctorListProvider>().setSearchQuery('');
    setState(() {
      _hasSearchText = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Your Doctors',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () => _showSortingOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<DoctorListProvider>().refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with rounded corners on both sides - matching the image
          // Replace your search bar Container section with this improved version:

          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 20), // Added bottom padding
            child: Container(
              height: 50, // Fixed height to prevent overflow
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                    25), // Half of height for perfect curve
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Search icon with proper padding
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),

                  // Text field with proper constraints
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Find a specialist doctor',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal:
                              0, // Remove horizontal padding since we handle it with Row
                        ),
                        isDense: true, // Helps with vertical alignment
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      textInputAction: TextInputAction.search,
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),

                  // Clear button with proper padding
                  if (_hasSearchText)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                        width: 16), // Maintain spacing when no clear button
                ],
              ),
            ),
          ),

          // Specialty filter chips
          _buildSpecialtyFilter(),

          // Main content
          Expanded(
            child: LoadingOverlay(
              isLoading: context.watch<DoctorListProvider>().isLoading,
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: () => context.read<DoctorListProvider>().refresh(),
                child: Consumer<DoctorListProvider>(
                  builder: (context, provider, child) {
                    if (provider.error != null) {
                      return _buildErrorState(provider.error!);
                    }

                    final doctors = provider.doctors;
                    if (doctors.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: doctors.length, // No +1 for session info
                      itemBuilder: (context, index) {
                        return DoctorCard(doctor: doctors[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Consumer<DoctorListProvider>(
          builder: (context, provider, child) {
            return Row(
              children: _specialties.map((specialty) {
                final isSelected = specialty == 'All'
                    ? provider.currentSpecialty.isEmpty
                    : provider.currentSpecialty == specialty;

                // Special styling for "All" as shown in image
                if (specialty == 'All') {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: isSelected ? primaryColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: primaryColor,
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          provider.setSpecialtyFilter('');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: isSelected ? Colors.white : primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                specialty,
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Other specialty chips - matching image exactly
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        provider.setSpecialtyFilter(
                            provider.currentSpecialty == specialty
                                ? ''
                                : specialty);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No doctors found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<DoctorListProvider>().refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 80,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<DoctorListProvider>().loadDoctors();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Sort doctors by',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSortOption(
                icon: Icons.sort_by_alpha,
                title: 'Name',
                sortBy: 'name',
              ),
              _buildSortOption(
                icon: Icons.medical_services,
                title: 'Specialty',
                sortBy: 'specialty',
              ),
              _buildSortOption(
                icon: Icons.stars,
                title: 'Experience',
                sortBy: 'experience',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required String sortBy,
  }) {
    return Consumer<DoctorListProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.sortBy == sortBy;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              provider.setSortBy(sortBy);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? primaryColor : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: primaryColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
