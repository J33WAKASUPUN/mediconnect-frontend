import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';

class MedicalRecordForm extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final Function(Map<String, dynamic>) onSubmit;

  const MedicalRecordForm({
    super.key,
    required this.appointmentId,
    required this.patientName,
    required this.onSubmit,
  });

  @override
  _MedicalRecordFormState createState() => _MedicalRecordFormState();
}

class _MedicalRecordFormState extends State<MedicalRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  final List<String> _tests = [];
  final TextEditingController _testController = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Medical Record'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical Record for ${widget.patientName}',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 24),
              
              // Diagnosis
              _buildTextField(
                controller: _diagnosisController,
                label: 'Diagnosis',
                hint: 'Enter diagnosis details',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Diagnosis is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Symptoms
              _buildTextField(
                controller: _symptomsController,
                label: 'Symptoms',
                hint: 'Enter patient symptoms',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Symptoms are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Treatment
              _buildTextField(
                controller: _treatmentController,
                label: 'Treatment',
                hint: 'Enter recommended treatment',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Treatment is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Prescription
              _buildTextField(
                controller: _prescriptionController,
                label: 'Prescription',
                hint: 'Enter medications prescribed',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Prescription is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Tests
              Text('Tests', style: AppStyles.subtitle1),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _testController,
                      decoration: const InputDecoration(
                        hintText: 'Add a test',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: _addTest,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Test list
              ..._tests.map((test) => _buildTestItem(test)),
              
              const SizedBox(height: 16),
              
              // Additional Notes
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                hint: 'Enter any additional notes',
                maxLines: 4,
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Save Medical Record',
                  icon: Icons.save,
                  isLoading: _isSubmitting,
                  onPressed: _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.subtitle1),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  void _addTest() {
    if (_testController.text.isNotEmpty) {
      setState(() {
        _tests.add(_testController.text);
        _testController.clear();
      });
    }
  }

  Widget _buildTestItem(String test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(child: Text(test)),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _tests.remove(test);
              });
            },
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      
      // Create data map
      final data = {
        'appointmentId': widget.appointmentId,
        'diagnosis': _diagnosisController.text,
        'symptoms': _symptomsController.text,
        'treatment': _treatmentController.text,
        'prescription': _prescriptionController.text,
        'tests': _tests,
        'notes': _notesController.text,
      };
      
      // Submit data
      widget.onSubmit(data);
    }
  }
}