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
  final ScrollController _scrollController = ScrollController();

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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          widget.patientName != null
              ? 'Medical Records - ${widget.patientName}'
              : 'Medical Records',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMedicalRecords,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            color: AppColors.primary,
            width: double.infinity,
            // padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     const Text(
            //       'Your Medical History',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 18,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     const SizedBox(height: 4),
            //     Text(
            //       'View and manage your health records',
            //       style: TextStyle(
            //         color: Colors.white.withOpacity(0.8),
            //         fontSize: 14,
            //       ),
            //     ),
            //   ],
            // ),
          ),
          
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : Consumer<MedicalRecordsProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: LoadingIndicator());
                      }

                      if (provider.error != null) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ErrorView(
                              message: provider.error!,
                              onRetry: _loadMedicalRecords,
                            ),
                          ],
                        );
                      }

                      if (provider.records.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadMedicalRecords,
                        child: ListView.builder(
                          controller: _scrollController,
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Medical Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You don\'t have any medical records yet.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadMedicalRecords,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    final doctorName = record.doctorName;
    final date = DateFormat('MMM dd, yyyy').format(record.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medical_services, 
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medical Record',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: record.status == 'final'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: record.status == 'final'
                              ? Colors.green
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        record.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
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

              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Doctor: $doctorName',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Diagnosis
                    Text(
                      'Diagnosis:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.diagnosis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Tags section
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (record.prescriptions.isNotEmpty)
                          _buildTag(
                            'Prescriptions',
                            Icons.medication_outlined,
                            Colors.green,
                          ),
                        if (record.testResults.isNotEmpty)
                          _buildTag(
                            'Test Results',
                            Icons.science_outlined,
                            Colors.orange,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // View Details Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}