import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../core/models/medical_record_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/medical_records_provider.dart';

class MedicalRecordViewer extends StatelessWidget {
  final String recordId;
  
  const MedicalRecordViewer({
    super.key,
    required this.recordId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MedicalRecord?>(
      future: Provider.of<MedicalRecordsProvider>(context, listen: false).getMedicalRecord(recordId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<MedicalRecordsProvider>(context, listen: false)
                        .getMedicalRecord(recordId);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final record = snapshot.data;
        if (record == null) {
          return const Center(child: Text('Medical record not found'));
        }
        
        return _buildRecordContent(context, record);
      },
    );
  }
  
  Widget _buildRecordContent(BuildContext context, MedicalRecord record) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(record),
            const SizedBox(height: 24),
            
            _buildSection('Diagnosis', record.diagnosis),
            
            // Handle different record formats
            if (record.prescriptions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Prescriptions', style: AppStyles.subtitle1),
              const SizedBox(height: 8),
              ...record.prescriptions.map((prescription) => _buildPrescriptionItem(prescription)),
              const SizedBox(height: 16),
            ],

            if (record.testResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Test Results', style: AppStyles.subtitle1),
              const SizedBox(height: 8),
              ...record.testResults.map((test) => _buildTestResultItem(test)),
              const SizedBox(height: 16),
            ],
            
            // Notes
            _buildSection('Additional Notes', record.notes),
            
            const SizedBox(height: 32),
            
            // PDF Download button
            Center(
              child: CustomButton(
                text: 'Generate PDF',
                icon: Icons.picture_as_pdf,
                onPressed: () => _generatePdf(context, record.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MedicalRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medical Record',
                style: AppStyles.heading2,
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(record.createdAt),
                style: AppStyles.bodyText1,
              ),
            ],
          ),
          const Divider(),
          _buildInfoRow('Doctor', record.doctorName),
          if (record.doctorDetails != null && 
              record.doctorDetails!['doctorProfile'] != null && 
              record.doctorDetails!['doctorProfile']['specialization'] != null)
            _buildInfoRow('Specialty', record.doctorDetails!['doctorProfile']['specialization']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyles.subtitle1),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppStyles.bodyText1,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrescriptionItem(Prescription prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prescription.medicine,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${prescription.dosage}, ${prescription.frequency}, ${prescription.duration}'),
            if (prescription.instructions != null && prescription.instructions!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Instructions: ${prescription.instructions}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultItem(TestResult test) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  test.testName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(test.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Result: ${test.result}'),
            if (test.normalRange != null && test.normalRange!.isNotEmpty)
              Text('Normal range: ${test.normalRange}'),
            if (test.remarks != null && test.remarks!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Remarks: ${test.remarks}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, String recordId) async {
    try {
      final pdfUrl = await Provider.of<MedicalRecordsProvider>(context, listen: false)
          .generatePdf(recordId);
      
      if (pdfUrl != null) {
        final Uri uri = Uri.parse(pdfUrl);
        if (await url_launcher.canLaunchUrl(uri)) {
          await url_launcher.launchUrl(uri);
        } else {
          throw Exception('Could not launch PDF');
        }
      } else {
        throw Exception('Failed to generate PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}