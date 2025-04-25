import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/models/medical_record_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final MedicalRecord record;
  
  const MedicalRecordDetailScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Record Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareRecord(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRecordDetails(),
            const SizedBox(height: 24),
            _buildDiagnosisSection(),
            const SizedBox(height: 24),
            _buildSymptomsTreatmentSection(),
            const SizedBox(height: 24),
            _buildPrescriptionsSection(),
            const SizedBox(height: 24),
            _buildTestsSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
          ],
        ),
      ),
      bottomNavigationBar: record.pdfUrl != null ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomButton(
          text: 'Download PDF',
          icon: Icons.download,
          onPressed: _downloadPDF,
        ),
      ) : null,
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Medical Record', style: AppStyles.heading2),
              ],
            ),
            const SizedBox(height: 8),
            Text('Date: ${record.formattedDate}', style: AppStyles.bodyText2),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record Details', style: AppStyles.heading2),
            const Divider(height: 24),
            _buildInfoRow('Doctor', record.doctorName),
            if (record.doctorSpecialty.isNotEmpty)
              _buildInfoRow('Specialty', record.doctorSpecialty),
            _buildInfoRow('Patient ID', record.patientId),
            _buildInfoRow('Visit Date', record.formattedDate),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diagnosis', style: AppStyles.heading2),
            const Divider(height: 24),
            Text(record.diagnosis, style: AppStyles.bodyText1),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsTreatmentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Symptoms & Treatment', style: AppStyles.heading2),
            const Divider(height: 24),
            _buildInfoRow('Symptoms', record.symptoms),
            const SizedBox(height: 16),
            _buildInfoRow('Treatment', record.treatment),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsSection() {
    if (record.prescription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prescription', style: AppStyles.heading2),
            const Divider(height: 24),
            Text(record.prescription, style: AppStyles.bodyText1),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsSection() {
    if (record.tests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tests', style: AppStyles.heading2),
            const Divider(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: record.tests.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.science, color: AppColors.primary),
                  title: Text(record.tests[index]),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    if (record.notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: AppStyles.heading2),
            const Divider(height: 24),
            Text(record.notes, style: AppStyles.bodyText1),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.bodyText1.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyText1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPDF() async {
    if (record.pdfUrl != null) {
      if (await canLaunchUrl(Uri.parse(record.pdfUrl!))) {
        await launchUrl(Uri.parse(record.pdfUrl!));
      }
    }
  }

  void _shareRecord(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality will be implemented in a future update')),
    );
  }
}