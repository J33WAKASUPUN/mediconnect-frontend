import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/profile_models.dart';
import '../../../core/utils/datetime_helper.dart';
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
      print("DoctorProfileSection updated with new profile");
    }
  }

  void _initializeProfile() {
    _editingProfile = widget.profile?.clone() ?? DoctorProfile();
  }

  Future<void> _saveChanges() async {
    try {
      await context
          .read<ProfileProvider>()
          .updateDoctorProfile(_editingProfile);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Professional information updated successfully')),
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

  // ignore: unused_element
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Basic Information
            if (_isEditing) 
              // Editing mode - show text fields
              Column(
                children: [
                  CustomTextField(
                    label: 'Specialization',
                    initialValue: _editingProfile.specialization,
                    enabled: true,
                    onChanged: (value) {
                      setState(() => _editingProfile.specialization = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'License Number',
                    initialValue: _editingProfile.licenseNumber,
                    enabled: true,
                    onChanged: (value) {
                      setState(() => _editingProfile.licenseNumber = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Years of Experience',
                    initialValue: _editingProfile.yearsOfExperience?.toString(),
                    enabled: true,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() =>
                          _editingProfile.yearsOfExperience = int.tryParse(value));
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Consultation Fees',
                    initialValue: _editingProfile.consultationFees?.toString(),
                    enabled: true,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() =>
                          _editingProfile.consultationFees = double.tryParse(value));
                    },
                  ),
                ],
              )
            else
              // View mode - show as regular text rows
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'Specialization:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(_editingProfile.specialization ?? 'Not specified'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'License Number:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(_editingProfile.licenseNumber ?? 'Not specified'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'Years of Experience:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(_editingProfile.yearsOfExperience?.toString() ?? 'Not specified'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text(
                            'Consultation Fees:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: _editingProfile.consultationFees != null 
                              ? Text('\$RS.{_editingProfile.consultationFees?.toString()}')
                              : const Text('Not specified'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Education
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Education',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.education.isEmpty)
                  const Text(
                    "No education information available",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ..._editingProfile.education.map((edu) => Card(
                      child: ListTile(
                        title: Text(edu.degree),
                        subtitle: Text('${edu.institution} (${edu.year})'),
                        trailing: _isEditing
                            ? IconButton(
                                icon: const Icon(Icons.delete),
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
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Hospital Affiliations
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital Affiliations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.hospitalAffiliations.isEmpty)
                  const Text(
                    "No hospital affiliations listed",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ..._editingProfile.hospitalAffiliations.map((affiliation) => Card(
                      child: ListTile(
                        title: Text(affiliation.hospitalName),
                        subtitle: Text(
                            '${affiliation.role} (Since ${DateTimeHelper.formatDate(affiliation.startDate)})'),
                        trailing: _isEditing
                            ? IconButton(
                                icon: const Icon(Icons.delete),
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
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Expertise
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Areas of Expertise',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.expertise.isEmpty)
                  const Text(
                    "No areas of expertise listed",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ...List.generate(_editingProfile.expertise.length, (index) {
                  final exp = _editingProfile.expertise[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(exp)),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete),
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
                if (_isEditing)
                  CustomButton(
                    text: 'Add Expertise',
                    onPressed: () => _addItem('Expertise', (value) {
                      setState(() => _editingProfile.expertise.add(value));
                    }),
                    isSecondary: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Available Time Slots
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_editingProfile.availableTimeSlots.isEmpty)
                  const Text(
                    "No available time slots",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ..._editingProfile.availableTimeSlots.map((slot) => Card(
                      child: ListTile(
                        title: Text(slot.day),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: slot.slots
                              .map((timeSlot) => Text(
                                  '${timeSlot.startTime} - ${timeSlot.endTime}'))
                              .toList(),
                        ),
                        trailing: _isEditing
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _editingProfile.availableTimeSlots.remove(slot);
                                  });
                                },
                              )
                            : null,
                      ),
                    )),
                if (_isEditing)
                  CustomButton(
                    text: 'Add Time Slot',
                    onPressed: _addTimeSlot,
                    isSecondary: true,
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

  Future<void> _addTimeSlot() async {
    final result = await showDialog<AvailableTimeSlot>(
      context: context,
      builder: (context) => const _AddTimeSlotDialog(),
    );
    if (result != null) {
      setState(() {
        _editingProfile.availableTimeSlots.add(result);
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

// Add Time Slot Dialog
class _AddTimeSlotDialog extends StatefulWidget {
  const _AddTimeSlotDialog();

  @override
  State<_AddTimeSlotDialog> createState() => _AddTimeSlotDialogState();
}

class _AddTimeSlotDialogState extends State<_AddTimeSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDay = 'Monday';
  final List<TimeSlot> _timeSlots = [];

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Available Time Slot'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
              ),
              items: _weekDays
                  .map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(day),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDay = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ..._timeSlots.map((slot) => ListTile(
                  title: Text('${slot.startTime} - ${slot.endTime}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _timeSlots.remove(slot));
                    },
                  ),
                )),
            CustomButton(
              text: 'Add Time Slot',
              onPressed: _addTimeSlot,
              isSecondary: true,
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
            if (_timeSlots.isNotEmpty) {
              Navigator.pop(
                context,
                AvailableTimeSlot(
                  day: _selectedDay,
                  slots: _timeSlots,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addTimeSlot() async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (startTime != null) {
      TimeOfDay? endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: startTime.hour + 1,
          minute: startTime.minute,
        ),
      );
      if (endTime != null) {
        setState(() {
          _timeSlots.add(TimeSlot(
            startTime: startTime.format(context),
            endTime: endTime.format(context),
          ));
        });
      }
    }
  }
}