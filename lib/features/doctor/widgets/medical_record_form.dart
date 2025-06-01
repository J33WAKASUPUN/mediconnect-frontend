import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/loading_indicator.dart';

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
  bool _isLoading = false;
  
  // Form fields
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Prescriptions
  final List<Map<String, TextEditingController>> _prescriptions = [];
  
  // Test results
  final List<Map<String, TextEditingController>> _testResults = [];
  
  // Next visit date
  DateTime? _nextVisitDate;
  
  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    
    // Clean up prescription controllers
    for (var prescription in _prescriptions) {
      prescription['medicine']?.dispose();
      prescription['dosage']?.dispose();
      prescription['frequency']?.dispose();
      prescription['duration']?.dispose();
      prescription['instructions']?.dispose();
    }
    
    // Clean up test result controllers
    for (var test in _testResults) {
      test['testName']?.dispose();
      test['result']?.dispose();
      test['normalRange']?.dispose();
      test['remarks']?.dispose();
    }
    
    super.dispose();
  }
  
  // Add a new prescription field
  void _addPrescription() {
    setState(() {
      _prescriptions.add({
        'medicine': TextEditingController(),
        'dosage': TextEditingController(),
        'frequency': TextEditingController(),
        'duration': TextEditingController(),
        'instructions': TextEditingController(),
      });
    });
  }
  
  // Remove a prescription field
  void _removePrescription(int index) {
    if (index < 0 || index >= _prescriptions.length) return;
    
    setState(() {
      final prescription = _prescriptions.removeAt(index);
      prescription['medicine']?.dispose();
      prescription['dosage']?.dispose();
      prescription['frequency']?.dispose();
      prescription['duration']?.dispose();
      prescription['instructions']?.dispose();
    });
  }
  
  // Add a new test result field
  void _addTestResult() {
    setState(() {
      _testResults.add({
        'testName': TextEditingController(),
        'result': TextEditingController(),
        'normalRange': TextEditingController(),
        'remarks': TextEditingController(),
      });
    });
  }
  
  // Remove a test result field
  void _removeTestResult(int index) {
    if (index < 0 || index >= _testResults.length) return;
    
    setState(() {
      final test = _testResults.removeAt(index);
      test['testName']?.dispose();
      test['result']?.dispose();
      test['normalRange']?.dispose();
      test['remarks']?.dispose();
    });
  }
  
  // Pick a date for next visit
  Future<void> _pickNextVisitDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextVisitDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != _nextVisitDate) {
      setState(() {
        _nextVisitDate = pickedDate;
      });
    }
  }

  // Submit the form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> data = {
        'diagnosis': _diagnosisController.text,
        'notes': _notesController.text,
      };
      
      // Add prescriptions if any
      if (_prescriptions.isNotEmpty) {
        data['prescriptions'] = _prescriptions.map((p) => {
          'medicine': p['medicine']!.text,
          'dosage': p['dosage']!.text,
          'frequency': p['frequency']!.text,
          'duration': p['duration']!.text,
          'instructions': p['instructions']!.text,
        }).toList();
      }
      
      // Add test results if any
      if (_testResults.isNotEmpty) {
        data['testResults'] = _testResults.map((t) => {
          'testName': t['testName']!.text,
          'result': t['result']!.text,
          'normalRange': t['normalRange']!.text,
          'remarks': t['remarks']!.text,
          'date': DateTime.now().toIso8601String(),
        }).toList();
      }
      
      // Add next visit date if set
      if (_nextVisitDate != null) {
        data['nextVisitDate'] = _nextVisitDate!.toIso8601String();
      }
      
      // Call the onSubmit callback
      widget.onSubmit(data);
    } catch (e) {
      print('Error creating medical record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
        title: const Text(
          'Create Medical Record',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                // Header section
                Container(
                  color: AppColors.primary,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Medical Record',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a medical record for ${widget.patientName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient info card
                          Container(
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Patient: ${widget.patientName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Appointment ID: ${widget.appointmentId}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Form Sections
                          _buildFormSection(
                            title: 'Diagnosis',
                            iconData: Icons.medical_information,
                            iconColor: Colors.blue,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            isRequired: true,
                            child: TextFormField(
                              controller: _diagnosisController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Enter the diagnosis',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a diagnosis';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Prescriptions Section
                          _buildFormSection(
                            title: 'Prescriptions',
                            iconData: Icons.medication,
                            iconColor: Colors.green,
                            backgroundColor: Colors.green.withOpacity(0.1),
                            isRequired: false,
                            action: TextButton.icon(
                              icon: const Icon(Icons.add, size: 20, color: Colors.green),
                              label: const Text(
                                'Add',
                                style: TextStyle(color: Colors.green),
                              ),
                              onPressed: _addPrescription,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            child: _prescriptions.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.medication_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No prescriptions added yet',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap the "Add" button to add a prescription',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      _prescriptions.length,
                                      (index) => _buildPrescriptionCard(index),
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Test Results Section
                          _buildFormSection(
                            title: 'Test Results',
                            iconData: Icons.science,
                            iconColor: Colors.orange,
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            isRequired: false,
                            action: TextButton.icon(
                              icon: const Icon(Icons.add, size: 20, color: Colors.orange),
                              label: const Text(
                                'Add',
                                style: TextStyle(color: Colors.orange),
                              ),
                              onPressed: _addTestResult,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            child: _testResults.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.science_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No test results added yet',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap the "Add" button to add a test result',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      _testResults.length,
                                      (index) => _buildTestResultCard(index),
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Next Visit Date Section
                          _buildFormSection(
                            title: 'Next Visit Date',
                            iconData: Icons.event_available,
                            iconColor: Colors.teal,
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            isRequired: false,
                            child: InkWell(
                              onTap: _pickNextVisitDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.teal.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      _nextVisitDate != null
                                          ? '${_nextVisitDate!.day}/${_nextVisitDate!.month}/${_nextVisitDate!.year}'
                                          : 'Select a date',
                                      style: _nextVisitDate != null
                                          ? const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                            )
                                          : TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Notes Section
                          _buildFormSection(
                            title: 'Notes',
                            iconData: Icons.notes,
                            iconColor: Colors.purple,
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            isRequired: true,
                            child: TextFormField(
                                                            controller: _notesController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Enter any additional notes',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter some notes';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Create Medical Record'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _submitForm,
          ),
        ),
      ),
    );
  }
  
  // Helper method to build form sections
  Widget _buildFormSection({
    required String title,
    required IconData iconData,
    required Color iconColor,
    required Color backgroundColor,
    required Widget child,
    Widget? action,
    bool isRequired = false,
  }) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400,
                    ),
                  ),
                const Spacer(),
                if (action != null) action,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
  
  // Build a prescription card
  Widget _buildPrescriptionCard(int index) {
    final medication = _prescriptions[index];
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary),
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Prescription #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removePrescription(index),
                splashRadius: 24,
                tooltip: 'Remove prescription',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: medication['medicine'],
            decoration: InputDecoration(
              labelText: 'Medicine *',
              hintText: 'Enter medicine name',
              border: inputBorder,
              focusedBorder: focusedBorder,
              enabledBorder: inputBorder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the medicine name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: medication['dosage'],
                  decoration: InputDecoration(
                    labelText: 'Dosage *',
                    hintText: 'e.g., 10mg',
                    border: inputBorder,
                    focusedBorder: focusedBorder,
                    enabledBorder: inputBorder,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: medication['frequency'],
                  decoration: InputDecoration(
                    labelText: 'Frequency *',
                    hintText: 'e.g., Twice daily',
                    border: inputBorder,
                    focusedBorder: focusedBorder,
                    enabledBorder: inputBorder,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: medication['duration'],
            decoration: InputDecoration(
              labelText: 'Duration *',
              hintText: 'e.g., 7 days',
              border: inputBorder,
              focusedBorder: focusedBorder,
              enabledBorder: inputBorder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the duration';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: medication['instructions'],
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Instructions (Optional)',
              hintText: 'e.g., Take after meals',
              border: inputBorder,
              focusedBorder: focusedBorder,
              enabledBorder: inputBorder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a test result card
  Widget _buildTestResultCard(int index) {
    final test = _testResults[index];
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary),
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Test Result #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeTestResult(index),
                splashRadius: 24,
                tooltip: 'Remove test result',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: test['testName'],
            decoration: InputDecoration(
              labelText: 'Test Name *',
              hintText: 'Enter test name',
              border: inputBorder,
              focusedBorder: focusedBorder,
              enabledBorder: inputBorder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the test name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: test['result'],
            decoration: InputDecoration(
              labelText: 'Result *',
              hintText: 'Enter test result',
              border: inputBorder,
              focusedBorder: focusedBorder,
              enabledBorder: inputBorder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the test result';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: test['normalRange'],
            decoration: InputDecoration(
              labelText: 'Normal Range (Optional)',
              hintText: 'e.g., 70-100 mg/dL',
              border: inputBorder,
              focusedBorder: focusedBorder,
              enabledBorder: inputBorder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: test['remarks'],
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Remarks (Optional)',
              hintText: 'Any additional notes about this test',
              border: inputBorder,
              focusedBorder: focusedBorder,
              enabledBorder: inputBorder,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
                              