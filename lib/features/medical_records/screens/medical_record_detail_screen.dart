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
          'Accept': 'application/pdf',
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
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Medical Record',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFFF6F6F6),
        body: const Center(child: LoadingIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Medical Record',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFFF6F6F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 70,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Error: $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadMedicalRecord,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_record == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Medical Record',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFFF6F6F6),
        body: const Center(
          child: Text('Record not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Medical Record',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareRecord,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with status
          Container(
            color: AppColors.primary,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical Record Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_record!.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
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
                    color: _record!.status == 'final'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _record!.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildDiagnosisSection(),
                  
                  if (_record!.prescriptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPrescriptionsSection(),
                  ],
                  
                  if (_record!.testResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTestResultsSection(),
                  ],
                  
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                  
                  if (_record!.nextVisitDate != null) ...[
                    const SizedBox(height: 16),
                    _buildNextVisitSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(_isDownloadingPdf ? 'Downloading...' : 'Download PDF'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            ),
            onPressed: _isDownloadingPdf ? null : _downloadPdf,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final patientName = widget.patientName ?? _record?.patientName ?? 'Patient';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
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
                  child: const Icon(Icons.info_outline, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Record Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                _buildInfoRow(
                  'Date',
                  DateFormat('MMM dd, yyyy').format(_record!.createdAt),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                widget.isDoctorView
                    ? _buildInfoRow('Patient', patientName, Icons.person)
                    : _buildInfoRow('Doctor', _record!.doctorName, Icons.medical_services),
                const SizedBox(height: 12),
                if (_record!.doctorSpecialty.isNotEmpty && !widget.isDoctorView)
                  _buildInfoRow('Specialty', _record!.doctorSpecialty, Icons.star),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDiagnosisSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
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
                    Icons.medical_information,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _record!.diagnosis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrescriptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
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
                    Icons.medication,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Prescriptions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _record!.prescriptions.map((prescription) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.medicine,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPrescriptionDetail('Dosage', prescription.dosage),
                      _buildPrescriptionDetail('Frequency', prescription.frequency),
                      _buildPrescriptionDetail('Duration', prescription.duration),
                      if (prescription.instructions != null && 
                          prescription.instructions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Instructions:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.instructions!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestResultsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
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
                    Icons.science,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Test Results',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _record!.testResults.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final test = _record!.testResults[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(test.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTestResultDetail('Result', test.result),
                    if (test.normalRange != null && test.normalRange!.isNotEmpty)
                      _buildTestResultDetail('Normal Range', test.normalRange!),
                    if (test.remarks != null && test.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Remarks:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.remarks!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
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
                    Icons.notes,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _record!.notes,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNextVisitSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
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
                    Icons.event_available,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Next Visit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today, 
                  color: Colors.teal,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recommended Date:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(_record!.nextVisitDate!),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label + ':',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}