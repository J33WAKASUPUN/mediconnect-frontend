import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/session_helper.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_textfield.dart';
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
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'General Medicine',
    'Orthopedics'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DoctorListProvider>().loadDoctors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = SessionHelper.getCurrentUTC();
    final userLogin = SessionHelper.getUserLogin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortingOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DoctorListProvider>().refresh(),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: context.watch<DoctorListProvider>().isLoading,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                controller: _searchController,
                label: 'Search Doctors',
                hint: 'Search by name or specialty',
                prefixIcon: Icons.search,
                onChanged: (value) {
                  context.read<DoctorListProvider>().setSearchQuery(value);
                },
              ),
            ),
            _buildSpecialtyFilter(),
            const Divider(),
            Expanded(
              child: RefreshIndicator(
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
                      padding: const EdgeInsets.all(16),
                      itemCount: doctors.length + 1, // +1 for session info
                      itemBuilder: (context, index) {
                        if (index == doctors.length) {
                          // Session info at the bottom
                          return Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): $currentTime',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Current User\'s Login: $userLogin',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }
                        return DoctorCard(doctor: doctors[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Consumer<DoctorListProvider>(
        builder: (context, provider, child) {
          return Row(
            children: _specialties.map((specialty) {
              final isSelected = specialty == 'All' 
                  ? provider.currentSpecialty.isEmpty
                  : provider.currentSpecialty == specialty;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(specialty),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.setSpecialtyFilter(
                      selected ? (specialty == 'All' ? '' : specialty) : ''
                    );
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          );
        },
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
            size: 64,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No doctors found',
            style: AppStyles.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: AppStyles.bodyText2,
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
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<DoctorListProvider>().loadDoctors();
            },
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
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sort by'),
                tileColor: AppColors.surface,
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Name'),
                onTap: () {
                  context.read<DoctorListProvider>().setSortBy('name');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('Specialty'),
                onTap: () {
                  context.read<DoctorListProvider>().setSortBy('specialty');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.stars),
                title: const Text('Experience'),
                onTap: () {
                  context.read<DoctorListProvider>().setSortBy('experience');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}