import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';
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
      appBar: AppBar(
        title: const Text('Create Medical Record'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient info header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: AppColors.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Patient: ${widget.patientName}',
                                  style: AppStyles.subtitle1,
                                ),
                                Text(
                                  'Appointment ID: ${widget.appointmentId}',
                                  style: AppStyles.bodyText2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Diagnosis
                    Text('Diagnosis *', style: AppStyles.subtitle1),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _diagnosisController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter the diagnosis',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a diagnosis';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Prescriptions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Prescriptions', style: AppStyles.subtitle1),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Prescription'),
                          onPressed: _addPrescription,
                        ),
                      ],
                    ),
                    
                    // List of prescription forms
                    if (_prescriptions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text(
                          'No prescriptions added yet',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: List.generate(
                          _prescriptions.length,
                          (index) => _buildPrescriptionCard(index),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Test Results
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Test Results', style: AppStyles.subtitle1),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Test Result'),
                          onPressed: _addTestResult,
                        ),
                      ],
                    ),
                    
                    // List of test result forms
                    if (_testResults.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text(
                          'No test results added yet',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: List.generate(
                          _testResults.length,
                          (index) => _buildTestResultCard(index),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Next Visit Date
                    Text('Next Visit Date (Optional)', style: AppStyles.subtitle1),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickNextVisitDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 16),
                            Text(
                              _nextVisitDate != null
                                  ? '${_nextVisitDate!.day}/${_nextVisitDate!.month}/${_nextVisitDate!.year}'
                                  : 'Select a date',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Notes
                    Text('Notes *', style: AppStyles.subtitle1),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter any additional notes',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some notes';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    Center(
                      child: CustomButton(
                        text: 'Create Medical Record',
                        icon: Icons.save,
                        onPressed: _submitForm,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Build a prescription card
  Widget _buildPrescriptionCard(int index) {
    final medication = _prescriptions[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prescription #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePrescription(index),
                ),
              ],
            ),
            const Divider(),
            TextFormField(
              controller: medication['medicine'],
              decoration: const InputDecoration(
                labelText: 'Medicine *',
                hintText: 'Enter medicine name',
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
                    decoration: const InputDecoration(
                      labelText: 'Dosage *',
                      hintText: 'e.g., 10mg',
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
                    decoration: const InputDecoration(
                      labelText: 'Frequency *',
                      hintText: 'e.g., Twice daily',
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
              decoration: const InputDecoration(
                labelText: 'Duration *',
                hintText: 'e.g., 7 days',
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
              decoration: const InputDecoration(
                labelText: 'Instructions (Optional)',
                hintText: 'e.g., Take after meals',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a test result card
  Widget _buildTestResultCard(int index) {
    final test = _testResults[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Test Result #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeTestResult(index),
                ),
              ],
            ),
            const Divider(),
            TextFormField(
              controller: test['testName'],
              decoration: const InputDecoration(
                labelText: 'Test Name *',
                hintText: 'Enter test name',
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
              decoration: const InputDecoration(
                labelText: 'Result *',
                hintText: 'Enter test result',
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
              decoration: const InputDecoration(
                labelText: 'Normal Range (Optional)',
                hintText: 'e.g., 70-100 mg/dL',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: test['remarks'],
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'Any additional notes about this test',
              ),
            ),
          ],
        ),
      ),
    );
  }
}