import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/profile_models.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../providers/profile_provider.dart';

class PatientProfileSection extends StatefulWidget {
  final PatientProfile? profile;
  final bool readOnly;

  const PatientProfileSection({
    super.key,
    required this.profile,
    this.readOnly = false,
  });

  @override
  State<PatientProfileSection> createState() => _PatientProfileSectionState();
}

class _PatientProfileSectionState extends State<PatientProfileSection> {
  bool _isEditing = false;
  late PatientProfile _editingProfile;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    print("PatientProfileSection initialized with: ${widget.profile}");
  }

  @override
  void didUpdateWidget(PatientProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _initializeProfile();
      print("PatientProfileSection updated with new profile");
    }
  }

  void _initializeProfile() {
    _editingProfile = widget.profile?.clone() ?? PatientProfile();
    print("_editingProfile initialized with: $_editingProfile");
  }

  Future<void> _saveChanges() async {
    try {
      await context
          .read<ProfileProvider>()
          .updatePatientProfile(_editingProfile);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medical information updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Never allow editing in readOnly mode
    if (widget.readOnly && _isEditing) {
      _isEditing = false;
    }

    // Print details about the patient profile
    print(
        "Building PatientProfileSection with bloodType: ${_editingProfile.bloodType}");
    print("Medical History: ${_editingProfile.medicalHistory}");
    print("Allergies: ${_editingProfile.allergies}");

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Blood Type Section
            _isEditing
                ?
                // Editing mode - dropdown
                DropdownButtonFormField<String>(
                    value: _editingProfile.bloodType,
                    decoration: const InputDecoration(
                      labelText: 'Blood Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _editingProfile.bloodType = value);
                    },
                  )
                :
                // View mode - regular text
                Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 120,
                          child: Text(
                            'Blood Type:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(_editingProfile.bloodType ?? 'Not specified'),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            // Medical History Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.medicalHistory.isEmpty)
                  const Text(
                    "No medical history information available",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ...List.generate(_editingProfile.medicalHistory.length,
                    (index) {
                  final history = _editingProfile.medicalHistory[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(history)),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _editingProfile.medicalHistory.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Medical History',
                    onPressed: () => _addItem('Medical History', (value) {
                      setState(() => _editingProfile.medicalHistory.add(value));
                    }),
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Allergies Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allergies',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.allergies.isEmpty)
                  const Text(
                    "No allergies listed",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ...List.generate(_editingProfile.allergies.length, (index) {
                  final allergy = _editingProfile.allergies[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(allergy)),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _editingProfile.allergies.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Allergy',
                    onPressed: () => _addItem('Allergy', (value) {
                      setState(() => _editingProfile.allergies.add(value));
                    }),
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Current Medications Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Medications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.currentMedications.isEmpty)
                  const Text(
                    "No current medications",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ...List.generate(_editingProfile.currentMedications.length,
                    (index) {
                  final medication = _editingProfile.currentMedications[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(medication)),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _editingProfile.currentMedications
                                    .removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Medication',
                    onPressed: () => _addItem('Medication', (value) {
                      setState(
                          () => _editingProfile.currentMedications.add(value));
                    }),
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Emergency Contacts Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.emergencyContacts.isEmpty)
                  const Text(
                    "No emergency contacts listed",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ...List.generate(_editingProfile.emergencyContacts.length,
                    (index) {
                  final contact = _editingProfile.emergencyContacts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(contact.name),
                      subtitle:
                          Text('${contact.relationship} - ${contact.phone}'),
                      trailing: _isEditing
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _editingProfile.emergencyContacts
                                      .removeAt(index);
                                });
                              },
                            )
                          : null,
                    ),
                  );
                }),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Emergency Contact',
                    onPressed: _addEmergencyContact,
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Insurance Information Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insurance Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isEditing
                        ?
                        // Editing mode - show input fields
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                label: 'Insurance Provider',
                                initialValue:
                                    _editingProfile.insuranceInfo?.provider,
                                enabled: true,
                                onChanged: (value) {
                                  setState(() {
                                    _editingProfile.insuranceInfo ??=
                                        InsuranceInfo();
                                    _editingProfile.insuranceInfo!.provider =
                                        value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                label: 'Policy Number',
                                initialValue:
                                    _editingProfile.insuranceInfo?.policyNumber,
                                enabled: true,
                                onChanged: (value) {
                                  setState(() {
                                    _editingProfile.insuranceInfo ??=
                                        InsuranceInfo();
                                    _editingProfile
                                        .insuranceInfo!.policyNumber = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              CustomButton(
                                text: 'Set Expiry Date',
                                onPressed: _selectExpiryDate,
                                isSecondary: true,
                              ),
                            ],
                          )
                        :
                        // View mode - show as regular text
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_editingProfile.insuranceInfo?.provider !=
                                  null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Provider:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(_editingProfile
                                            .insuranceInfo!.provider!),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_editingProfile.insuranceInfo?.policyNumber !=
                                  null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Policy Number:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(_editingProfile
                                            .insuranceInfo!.policyNumber!),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_editingProfile.insuranceInfo?.expiryDate !=
                                  null)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Expiry Date:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(_formatDate(_editingProfile
                                        .insuranceInfo!.expiryDate!)),
                                  ],
                                ),
                              if (_editingProfile.insuranceInfo == null ||
                                  (_editingProfile.insuranceInfo?.provider ==
                                          null &&
                                      _editingProfile
                                              .insuranceInfo?.policyNumber ==
                                          null &&
                                      _editingProfile
                                              .insuranceInfo?.expiryDate ==
                                          null))
                                const Text(
                                  "No insurance information available",
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chronic Conditions Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chronic Conditions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.chronicConditions.isEmpty)
                  const Text(
                    "No chronic conditions listed",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ...List.generate(_editingProfile.chronicConditions.length,
                    (index) {
                  final condition = _editingProfile.chronicConditions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(condition)),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _editingProfile.chronicConditions
                                    .removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Chronic Condition',
                    onPressed: () => _addItem('Chronic Condition', (value) {
                      setState(
                          () => _editingProfile.chronicConditions.add(value));
                    }),
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Last Checkup Date
            if (_editingProfile.lastCheckupDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Checkup Date',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(_editingProfile.lastCheckupDate!),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),

            // Action Buttons - Only show if not in readOnly mode
            if (!widget.readOnly)
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: _isEditing ? 'Save Changes' : 'Edit Information',
                      onPressed: () {
                        if (_isEditing) {
                          _saveChanges();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                      icon: _isEditing ? Icons.save : Icons.edit,
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _initializeProfile();
                          });
                        },
                        isSecondary: true,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addItem(String title, Function(String) onAdd) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddItemDialog(title: title),
    );
    if (result != null && result.isNotEmpty) {
      onAdd(result);
    }
  }

  Future<void> _addEmergencyContact() async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => const _AddEmergencyContactDialog(),
    );
    if (result != null) {
      setState(() {
        _editingProfile.emergencyContacts.add(result);
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _editingProfile.insuranceInfo?.expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() {
        _editingProfile.insuranceInfo ??= InsuranceInfo();
        _editingProfile.insuranceInfo!.expiryDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Add Item Dialog
class _AddItemDialog extends StatefulWidget {
  final String title;

  const _AddItemDialog({required this.title});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.title}'),
      content: CustomTextField(
        controller: _controller,
        label: widget.title,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Emergency Contact Dialog
class _AddEmergencyContactDialog extends StatefulWidget {
  const _AddEmergencyContactDialog();

  @override
  State<_AddEmergencyContactDialog> createState() =>
      _AddEmergencyContactDialogState();
}

class _AddEmergencyContactDialogState
    extends State<_AddEmergencyContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _relationshipController,
              label: 'Relationship',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Relationship is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                EmergencyContact(
                  name: _nameController.text,
                  relationship: _relationshipController.text,
                  phone: _phoneController.text,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
