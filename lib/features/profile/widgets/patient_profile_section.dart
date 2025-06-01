import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/profile_models.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
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
  }

  @override
  void didUpdateWidget(PatientProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _initializeProfile();
    }
  }

  void _initializeProfile() {
    _editingProfile = widget.profile?.clone() ?? PatientProfile();
  }

  Future<void> _saveChanges() async {
    try {
      await context
          .read<ProfileProvider>()
          .updatePatientProfile(_editingProfile);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medical information updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with icon
            Row(
              children: [
                Icon(Icons.medical_services, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Medical Information',
                  style: AppStyles.heading3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: 24),

            // Blood Type Section
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bloodtype, 
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Blood Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isEditing
                    ? DropdownButtonFormField<String>(
                        value: _editingProfile.bloodType,
                        decoration: InputDecoration(
                          labelText: 'Blood Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, 
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite, 
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _editingProfile.bloodType ?? 'Not specified',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),

            // Medical History Section
            _buildSectionWithItems(
              title: 'Medical History',
              icon: Icons.history,
              items: _editingProfile.medicalHistory,
              emptyMessage: "No medical history information available",
              onAdd: () => _addItem('Medical History', (value) {
                setState(() => _editingProfile.medicalHistory.add(value));
              }),
              onDelete: (index) {
                setState(() {
                  _editingProfile.medicalHistory.removeAt(index);
                });
              },
            ),

            // Allergies Section
            _buildSectionWithItems(
              title: 'Allergies',
              icon: Icons.warning_amber,
              items: _editingProfile.allergies,
              emptyMessage: "No allergies listed",
              onAdd: () => _addItem('Allergy', (value) {
                setState(() => _editingProfile.allergies.add(value));
              }),
              onDelete: (index) {
                setState(() {
                  _editingProfile.allergies.removeAt(index);
                });
              },
            ),

            // Current Medications Section
            _buildSectionWithItems(
              title: 'Current Medications',
              icon: Icons.medication,
              items: _editingProfile.currentMedications,
              emptyMessage: "No current medications",
              onAdd: () => _addItem('Medication', (value) {
                setState(() => _editingProfile.currentMedications.add(value));
              }),
              onDelete: (index) {
                setState(() {
                  _editingProfile.currentMedications.removeAt(index);
                });
              },
            ),

            // Emergency Contacts Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emergency,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_editingProfile.emergencyContacts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "No emergency contacts listed",
                        style: TextStyle(
                          fontStyle: FontStyle.italic, 
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ..._editingProfile.emergencyContacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_isEditing)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _editingProfile.emergencyContacts.removeAt(index);
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.only(left: 38),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Relationship: ${contact.relationship}',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      contact.phone,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: CustomButton(
                      text: 'Add Emergency Contact',
                      onPressed: _addEmergencyContact,
                      isSecondary: true,
                      icon: Icons.add,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Insurance Information Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Insurance Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'Insurance Provider',
                            initialValue: _editingProfile.insuranceInfo?.provider,
                            prefixIcon: Icons.business,
                            enabled: true,
                            onChanged: (value) {
                              setState(() {
                                _editingProfile.insuranceInfo ??= InsuranceInfo();
                                _editingProfile.insuranceInfo!.provider = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Policy Number',
                            initialValue: _editingProfile.insuranceInfo?.policyNumber,
                            prefixIcon: Icons.numbers,
                            enabled: true,
                            onChanged: (value) {
                              setState(() {
                                _editingProfile.insuranceInfo ??= InsuranceInfo();
                                _editingProfile.insuranceInfo!.policyNumber = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today),
                                      const SizedBox(width: 8),
                                      Text(
                                        _editingProfile.insuranceInfo?.expiryDate != null
                                            ? _formatDate(_editingProfile.insuranceInfo!.expiryDate!)
                                            : 'No Expiry Date Set',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustomButton(
                                text: 'Set Expiry',
                                onPressed: _selectExpiryDate,
                                isSecondary: true,
                                icon: Icons.edit_calendar,
                              ),
                            ],
                          ),
                        ],
                      )
                    : _editingProfile.insuranceInfo == null ||
                        (_editingProfile.insuranceInfo?.provider == null &&
                          _editingProfile.insuranceInfo?.policyNumber == null &&
                          _editingProfile.insuranceInfo?.expiryDate == null)
                        ? const Center(
                            child: Text(
                              "No insurance information available",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              if (_editingProfile.insuranceInfo?.provider != null)
                                _buildInsuranceInfoRow(
                                  'Provider',
                                  _editingProfile.insuranceInfo!.provider!,
                                  Icons.business,
                                ),
                              if (_editingProfile.insuranceInfo?.policyNumber != null)
                                _buildInsuranceInfoRow(
                                  'Policy Number',
                                  _editingProfile.insuranceInfo!.policyNumber!,
                                  Icons.numbers,
                                ),
                              if (_editingProfile.insuranceInfo?.expiryDate != null)
                                _buildInsuranceInfoRow(
                                  'Expiry Date',
                                  _formatDate(_editingProfile.insuranceInfo!.expiryDate!),
                                  Icons.calendar_today,
                                ),
                            ],
                          ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chronic Conditions Section
            _buildSectionWithItems(
              title: 'Chronic Conditions',
              icon: Icons.healing,
              items: _editingProfile.chronicConditions,
              emptyMessage: "No chronic conditions listed",
              onAdd: () => _addItem('Chronic Condition', (value) {
                setState(() => _editingProfile.chronicConditions.add(value));
              }),
              onDelete: (index) {
                setState(() {
                  _editingProfile.chronicConditions.removeAt(index);
                });
              },
            ),

            // Last Checkup Date
            if (_editingProfile.lastCheckupDate != null)
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Checkup Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_editingProfile.lastCheckupDate!),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
  
  Widget _buildSectionWithItems({
    required String title,
    required IconData icon,
    required List<String> items,
    required String emptyMessage,
    required VoidCallback onAdd,
    required Function(int) onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: items.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Column(
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item),
                          ),
                          if (_isEditing)
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => onDelete(index),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: CustomButton(
                text: 'Add $title Item',
                onPressed: onAdd,
                isSecondary: true,
                icon: Icons.add,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsuranceInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
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

class _AddEmergencyContactDialogState extends State<_AddEmergencyContactDialog> {
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
              prefixIcon: Icons.person,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _relationshipController,
              label: 'Relationship',
              prefixIcon: Icons.people,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Relationship is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              prefixIcon: Icons.phone,
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