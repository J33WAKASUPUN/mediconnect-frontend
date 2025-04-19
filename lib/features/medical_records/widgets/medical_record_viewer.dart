import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/medical_record_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';

class MedicalRecordViewer extends StatelessWidget {
  final MedicalRecord record;

  const MedicalRecordViewer({
    Key? key,
    required this.record,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            _buildSection('Diagnosis', record.diagnosis),
            _buildSection('Symptoms', record.symptoms),
            _buildSection('Treatment', record.treatment),
            
            // Prescription
            _buildSection('Prescription', record.prescription),
            
            // Tests
            if (record.tests.isNotEmpty) ...[
              Text('Tests', style: AppStyles.heading3),
              const SizedBox(height: 8),
              ...record.tests.map((test) => _buildBulletItem(test)).toList(),
              const SizedBox(height: 16),
            ],
            
            // Notes
            _buildSection('Additional Notes', record.notes),
            
            const SizedBox(height: 32),
            
            // PDF Download button
            if (record.pdfUrl != null)
              Center(
                child: CustomButton(
                  text: 'View/Download PDF',
                  icon: Icons.picture_as_pdf,
                  onPressed: () => _openPdf(record.pdfUrl!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                DateFormat('MMM dd, yyyy').format(record.date),
                style: AppStyles.bodyText1,
              ),
            ],
          ),
          const Divider(),
          _buildInfoRow('Doctor', record.doctorName),
          if (record.doctorSpecialty.isNotEmpty)
            _buildInfoRow('Specialty', record.doctorSpecialty),
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
        Text(title, style: AppStyles.heading3),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppStyles.bodyText1,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyText1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}