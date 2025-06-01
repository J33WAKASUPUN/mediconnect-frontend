import 'package:flutter/material.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/utils/datetime_helper.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../providers/profile_provider.dart';

class DoctorProfileSection extends StatefulWidget {
  final DoctorProfile? profile;

  const DoctorProfileSection({
    super.key,
    required this.profile,
  });

  @override
  State<DoctorProfileSection> createState() => _DoctorProfileSectionState();
}

class _DoctorProfileSectionState extends State<DoctorProfileSection> {
  bool _isEditing = false;
  late DoctorProfile _editingProfile;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  @override
  void didUpdateWidget(DoctorProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _initializeProfile();
    }
  }

  void _initializeProfile() {
    _editingProfile = widget.profile?.clone() ?? DoctorProfile();
    _editingProfile.availableTimeSlots = [];
  }

  Future<void> _saveChanges() async {
    try {
      _editingProfile.availableTimeSlots = [];

      await context
          .read<ProfileProvider>()
          .updateDoctorProfile(_editingProfile);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Professional information updated successfully'),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header with icon
            Row(
              children: [
                Icon(Icons.medical_services, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Professional Information',
                  style: AppStyles.heading3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: 24),

            // Basic Information
            if (_isEditing)
              // Editing mode - show text fields
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctor Details',
                    style: AppStyles.subtitle1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Specialization',
                    initialValue: _editingProfile.specialization,
                    enabled: true,
                    prefixIcon: Icons.local_hospital,
                    onChanged: (value) {
                      setState(() => _editingProfile.specialization = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'License Number',
                    initialValue: _editingProfile.licenseNumber,
                    enabled: true,
                    prefixIcon: Icons.badge,
                    onChanged: (value) {
                      setState(() => _editingProfile.licenseNumber = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Years of Experience',
                    initialValue: _editingProfile.yearsOfExperience?.toString(),
                    enabled: true,
                    prefixIcon: Icons.timeline,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _editingProfile.yearsOfExperience =
                          int.tryParse(value));
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Consultation Fees',
                    initialValue: _editingProfile.consultationFees?.toString(),
                    enabled: true,
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _editingProfile.consultationFees =
                          double.tryParse(value));
                    },
                  ),
                ],
              )
            else
              // View mode - show as styled info cards
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.stars, 
                          color: AppColors.primary, 
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Doctor Details',
                          style: AppStyles.subtitle1.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Specialization',
                      _editingProfile.specialization ?? 'Not specified',
                      Icons.local_hospital,
                    ),
                    _buildInfoRow(
                      'License Number',
                      _editingProfile.licenseNumber ?? 'Not specified',
                      Icons.badge,
                    ),
                    _buildInfoRow(
                      'Years of Experience',
                      _editingProfile.yearsOfExperience?.toString() ?? 'Not specified',
                      Icons.timeline,
                    ),
                    _buildInfoRow(
                      'Consultation Fees',
                      _editingProfile.consultationFees != null
                          ? 'Rs. ${_editingProfile.consultationFees?.toString()}'
                          : 'Not specified',
                      Icons.monetization_on,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Education
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Education',
                      style: AppStyles.subtitle1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_editingProfile.education.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "No education information available",
                        style: TextStyle(
                          fontStyle: FontStyle.italic, 
                          color: Colors.grey
                        ),
                      ),
                    ),
                  ),
                ..._editingProfile.education.map((edu) => Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.school_outlined,
                      color: AppColors.secondary,
                    ),
                    title: Text(
                      edu.degree,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${edu.institution} (${edu.year})'),
                    trailing: _isEditing
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _editingProfile.education.remove(edu);
                              });
                            },
                          )
                        : null,
                  ),
                )),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Education',
                    onPressed: _addEducation,
                    isSecondary: true,
                    icon: Icons.add,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Hospital Affiliations
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_hospital, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Hospital Affiliations',
                      style: AppStyles.subtitle1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_editingProfile.hospitalAffiliations.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "No hospital affiliations listed",
                        style: TextStyle(
                          fontStyle: FontStyle.italic, 
                          color: Colors.grey
                        ),
                      ),
                    ),
                  ),
                ..._editingProfile.hospitalAffiliations
                  .map((affiliation) => Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.business, 
                        color: AppColors.secondary,
                      ),
                      title: Text(
                        affiliation.hospitalName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                          '${affiliation.role} (Since ${DateTimeHelper.formatDate(affiliation.startDate)})'),
                      trailing: _isEditing
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _editingProfile.hospitalAffiliations
                                      .remove(affiliation);
                                });
                              },
                            )
                          : null,
                    ),
                  )),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Hospital Affiliation',
                    onPressed: _addHospitalAffiliation,
                    isSecondary: true,
                    icon: Icons.add,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Expertise
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Areas of Expertise',
                      style: AppStyles.subtitle1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _editingProfile.expertise.isEmpty
                    ? const Center(
                        child: Text(
                          "No areas of expertise listed",
                          style: TextStyle(
                            fontStyle: FontStyle.italic, 
                            color: Colors.grey
                          ),
                        ),
                      )
                    : Column(
                        children: List.generate(_editingProfile.expertise.length, (index) {
                          final exp = _editingProfile.expertise[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    exp,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  )
                                ),
                                if (_isEditing)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _editingProfile.expertise.removeAt(index);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: CustomButton(
                      text: 'Add Expertise',
                      onPressed: () => _addItem('Expertise', (value) {
                        setState(() => _editingProfile.expertise.add(value));
                      }),
                      isSecondary: true,
                      icon: Icons.add,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
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
            
            // View Working Hours Link
            if (!_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/doctor/calendar',
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text("View Working Hours"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method for displaying info in rows with labels and icons
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog helpers
  Future<void> _addItem(String title, Function(String) onAdd) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddItemDialog(title: title),
    );
    if (result != null && result.isNotEmpty) {
      onAdd(result);
    }
  }

  Future<void> _addEducation() async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) => const _AddEducationDialog(),
    );
    if (result != null) {
      setState(() {
        _editingProfile.education.add(result);
      });
    }
  }

  Future<void> _addHospitalAffiliation() async {
    final result = await showDialog<HospitalAffiliation>(
      context: context,
      builder: (context) => const _AddHospitalAffiliationDialog(),
    );
    if (result != null) {
      setState(() {
        _editingProfile.hospitalAffiliations.add(result);
      });
    }
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

// Add Education Dialog
class _AddEducationDialog extends StatefulWidget {
  const _AddEducationDialog();

  @override
  State<_AddEducationDialog> createState() => _AddEducationDialogState();
}

class _AddEducationDialogState extends State<_AddEducationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _degreeController = TextEditingController();
  final _institutionController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void dispose() {
    _degreeController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Education'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _degreeController,
              label: 'Degree',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Degree is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _institutionController,
              label: 'Institution',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Institution is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _yearController,
              label: 'Year',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Year is required';
                }
                if (int.tryParse(value!) == null) {
                  return 'Please enter a valid year';
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
                Education(
                  degree: _degreeController.text,
                  institution: _institutionController.text,
                  year: int.parse(_yearController.text),
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

// Add Hospital Affiliation Dialog
class _AddHospitalAffiliationDialog extends StatefulWidget {
  const _AddHospitalAffiliationDialog();

  @override
  State<_AddHospitalAffiliationDialog> createState() =>
      _AddHospitalAffiliationDialogState();
}

class _AddHospitalAffiliationDialogState
    extends State<_AddHospitalAffiliationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalNameController = TextEditingController();
  final _roleController = TextEditingController();
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Hospital Affiliation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _hospitalNameController,
              label: 'Hospital Name',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Hospital name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _roleController,
              label: 'Role',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Role is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Start Date: ${DateTimeHelper.formatDate(_startDate)}'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: const Text('Select Date'),
                ),
              ],
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
                HospitalAffiliation(
                  hospitalName: _hospitalNameController.text,
                  role: _roleController.text,
                  startDate: _startDate,
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