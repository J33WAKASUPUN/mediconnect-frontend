import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../core/models/medical_record_model.dart';
import '../../../core/services/api_service.dart';
import '../../../config/api_endpoints.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/medical_records_provider.dart';

class MedicalRecordDetailScreen extends StatefulWidget {
  final String recordId;
  final String? patientName;
  final bool isDoctorView;
  
  const MedicalRecordDetailScreen({
    super.key,
    required this.recordId,
    this.patientName,
    this.isDoctorView = false,
  });

  @override
  _MedicalRecordDetailScreenState createState() => _MedicalRecordDetailScreenState();
}

class _MedicalRecordDetailScreenState extends State<MedicalRecordDetailScreen> {
  bool _isLoading = true;
  String? _error;
  MedicalRecord? _record;
  bool _isDownloadingPdf = false;
  
  @override
  void initState() {
    super.initState();
    _loadMedicalRecord();
  }
  
  Future<void> _loadMedicalRecord() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final recordsProvider = Provider.of<MedicalRecordsProvider>(context, listen: false);
      final record = await recordsProvider.getMedicalRecord(widget.recordId);
      
      setState(() {
        _record = record;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medical record: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      // Get the API service
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Make a direct API call with responseType set to bytes
      final response = await apiService.httpClient.get(
        Uri.parse('${ApiEndpoints.baseUrl}/medical-records/record/${widget.recordId}/pdf?download=true'),
        headers: {
          'Authorization': 'Bearer ${apiService.authToken}',
          'Accept': 'application/pdf', // Important: tell server we want PDF
        },
      );
      
      if (response.statusCode == 200) {
        // The response is a PDF file, save it to device
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/medical_record_${widget.recordId}.pdf';
        
        // Write the bytes to a file
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Open the PDF with a PDF viewer
        final result = await OpenFile.open(filePath);
        
        if (result.type != ResultType.done) {
          throw Exception('Could not open PDF: ${result.message}');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print("Error downloading PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }
  
  void _shareRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality not implemented yet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Medical Record'),
        ),
        body: const Center(child: LoadingIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Medical Record'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMedicalRecord,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_record == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Medical Record'),
        ),
        body: const Center(
          child: Text('Record not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRecord,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDiagnosisSection(),
            const SizedBox(height: 24),
            if (_record!.prescriptions.isNotEmpty) ...[
              _buildPrescriptionsSection(),
              const SizedBox(height: 24),
            ],
            if (_record!.testResults.isNotEmpty) ...[
              _buildTestResultsSection(),
              const SizedBox(height: 24),
            ],
            _buildNotesSection(),
            if (_record!.nextVisitDate != null) ...[
              const SizedBox(height: 24),
              _buildNextVisitSection(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          text: _isDownloadingPdf ? 'Downloading...' : 'Download PDF',
          icon: Icons.picture_as_pdf,
          isLoading: _isDownloadingPdf,
          onPressed: _isDownloadingPdf ? null : _downloadPdf,
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    final patientName = widget.patientName ?? _record?.patientName ?? 'Patient';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Medical Record',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _record!.status == 'final' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _record!.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _record!.status == 'final' ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Date:',
              DateFormat('MMM dd, yyyy').format(_record!.createdAt),
              Icons.calendar_today,
            ),
            widget.isDoctorView
                ? _buildInfoRow('Patient:', patientName, Icons.person)
                : _buildInfoRow('Doctor:', _record!.doctorName, Icons.medical_services),
            if (_record!.doctorSpecialty.isNotEmpty && !widget.isDoctorView)
              _buildInfoRow('Specialty:', _record!.doctorSpecialty, Icons.star),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiagnosisSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_information, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_record!.diagnosis),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrescriptionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medication, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Prescriptions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _record!.prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = _record!.prescriptions[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const Divider(height: 32),
                    Text(
                      prescription.medicine,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Dosage: ${prescription.dosage}'),
                    Text('Frequency: ${prescription.frequency}'),
                    Text('Duration: ${prescription.duration}'),
                    if (prescription.instructions != null && prescription.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Instructions:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(prescription.instructions!),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestResultsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Test Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _record!.testResults.length,
              itemBuilder: (context, index) {
                final test = _record!.testResults[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          test.testName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(test.date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Result: ${test.result}'),
                    if (test.normalRange != null && test.normalRange!.isNotEmpty)
                      Text('Normal Range: ${test.normalRange}'),
                    if (test.remarks != null && test.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Remarks:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(test.remarks!),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notes, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_record!.notes),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNextVisitSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_available, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Next Visit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recommended Date: ${DateFormat('MMM dd, yyyy').format(_record!.nextVisitDate!)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}