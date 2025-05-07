import 'package:flutter/material.dart';
import 'package:mediconnect/core/services/api_service.dart';
import 'package:mediconnect/features/medical_records/providers/medical_records_provider.dart';
import 'package:mediconnect/features/medical_records/screens/medical_record_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/medical_record_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';

class PatientMedicalRecordsScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const PatientMedicalRecordsScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  _PatientMedicalRecordsScreenState createState() =>
      _PatientMedicalRecordsScreenState();
}

class _PatientMedicalRecordsScreenState
    extends State<PatientMedicalRecordsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadMedicalRecords);
  }

  Future<void> _loadMedicalRecords() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider =
          Provider.of<MedicalRecordsProvider>(context, listen: false);

      // Use specific patient ID if provided
      if (widget.patientId != null) {
        await provider.loadPatientMedicalRecordsById(widget.patientId!);
      } else {
        // Otherwise load current user's records
        await provider.loadPatientMedicalRecords();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName != null
            ? 'Medical Records - ${widget.patientName}'
            : 'Medical Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedicalRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : Consumer<MedicalRecordsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingIndicator();
                }

                if (provider.error != null) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ErrorView(
                        message: provider.error!,
                        onRetry: _loadMedicalRecords,
                      ),
                      // Debug button for development
                      if (true) // Set to false in production
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final apiService = Provider.of<ApiService>(
                                  context,
                                  listen: false);
                              final profileResponse =
                                  await apiService.get('/profile');
                              print("Profile response: $profileResponse");

                              if (profileResponse['success'] &&
                                  profileResponse['data'] != null) {
                                final patientId =
                                    profileResponse['data']['_id'];
                                print("Patient ID: $patientId");

                                final recordsResponse = await apiService
                                    .get('/medical-records/patient/$patientId');
                                print(
                                    "Medical records response: $recordsResponse");
                              }
                            } catch (e) {
                              print("Debug API error: $e");
                            }
                          },
                          child: const Text('Debug API'),
                        ),
                    ],
                  );
                }

                if (provider.records.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _loadMedicalRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.records.length,
                    itemBuilder: (context, index) {
                      final record = provider.records[index];
                      return _buildMedicalRecordCard(record);
                    },
                  ),
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
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Medical Records',
            style: AppStyles.heading2,
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have any medical records yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    final doctorName = record.doctorName;
    final date = DateFormat('MMM dd, yyyy').format(record.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicalRecordDetailScreen(
                recordId: record.id,
                isDoctorView: false,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Record',
                          style: AppStyles.subtitle1,
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: record.status == 'final'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      record.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: record.status == 'final'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Doctor: $doctorName',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diagnosis: ${record.diagnosis}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Show prescription and tests info if available
                  if (record.prescriptions.isNotEmpty)
                    const Text(
                      'Includes Prescription',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),

                  if (record.testResults.isNotEmpty)
                    const Text(
                      'Includes Test Results',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),

                  const SizedBox(height: 16),

                  // View Details Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicalRecordDetailScreen(
                                recordId: record.id,
                                isDoctorView: false,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
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
    );
  }
}
