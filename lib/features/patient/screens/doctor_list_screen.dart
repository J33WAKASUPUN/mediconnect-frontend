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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search bar
                _buildSearchBar(),
                
                // Filter chips
                _buildSpecialtyFilter(),
                
                // Doctor counter
                Consumer<DoctorListProvider>(
                  builder: (context, provider, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${provider.doctors.length} Doctor${provider.doctors.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (provider.doctors.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _showSortingOptions(context),
                              icon: const Icon(Icons.sort, size: 16),
                              label: const Text('Sort'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Doctor list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Consumer<DoctorListProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (provider.error != null) {
                  return SliverFillRemaining(
                    child: _buildErrorState(provider.error!),
                  );
                }
                
                final doctors = provider.doctors;
                if (doctors.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => DoctorCard(doctor: doctors[index]),
                    childCount: doctors.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Your Doctors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.7),
                AppColors.primary,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => context.read<DoctorListProvider>().refresh(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
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
                    horizontal: 0,
                  ),
                  isDense: true,
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
              const SizedBox(width: 16),
          ],
        ),
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

                // Special styling for selected specialty
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected ? AppColors.primary : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        provider.setSpecialtyFilter(
                            specialty == 'All' ? '' : specialty);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: specialty == 'All' && isSelected ? 16 : 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (specialty == 'All' && isSelected)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                              ),
                            Text(
                              specialty,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade800,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
            color: AppColors.primary.withOpacity(0.3),
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
              backgroundColor: AppColors.primary,
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
              backgroundColor: AppColors.primary,
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
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppColors.primary : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
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