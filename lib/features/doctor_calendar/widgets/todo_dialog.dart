import 'package:flutter/material.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import '../../../core/models/todo_model.dart';

class AddTodoDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Todo? existingTodo;
  final Function(Todo) onSave;

  const AddTodoDialog({
    super.key,
    required this.selectedDate,
    this.existingTodo,
    required this.onSave,
  });

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _priority = 'medium';
  TimeOfDay? _selectedTime;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingTodo != null;
    
    _titleController = TextEditingController(
      text: widget.existingTodo?.title ?? '',
    );
    
    _descriptionController = TextEditingController(
      text: widget.existingTodo?.description ?? '',
    );
    
    _priority = widget.existingTodo?.priority ?? 'medium';
    
    if (widget.existingTodo?.time != null && widget.existingTodo!.time!.isNotEmpty) {
      final timeParts = widget.existingTodo!.time!.split(':');
      try {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]), 
          minute: int.parse(timeParts[1]),
        );
      } catch (_) {
        _selectedTime = null;
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${widget.selectedDate.day} ${_getMonthName(widget.selectedDate.month)} ${widget.selectedDate.year}";
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isEditing ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isEditing ? Colors.blue : Colors.orange).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_note : Icons.task_alt,
                      color: _isEditing ? Colors.blue : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Task' : 'Add New Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isEditing ? Colors.blue : Colors.orange,
                          ),
                        ),
                        Text(
                          'For $dateStr',
                          style: TextStyle(
                            fontSize: 14,
                            color: (_isEditing ? Colors.blue : Colors.orange).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter task title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        prefixIcon: Icon(
                          Icons.title,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Add more details about this task',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: Icon(
                          Icons.description,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 16),
                    
                    // Priority selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flag,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildPriorityOption('Low', 'low'),
                            const SizedBox(width: 12),
                            _buildPriorityOption('Medium', 'medium'),
                            const SizedBox(width: 12),
                            _buildPriorityOption('High', 'high'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Time selection
                    GestureDetector(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Time (optional):',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _selectedTime != null
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _selectedTime = null;
                                            });
                                          },
                                          tooltip: 'Clear time',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Not set',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _saveTodo,
                          icon: Icon(
                            _isEditing ? Icons.check : Icons.add,
                            size: 18,
                          ),
                          label: Text(_isEditing ? 'Update' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String label, String value) {
    final bool isSelected = _priority == value;
    final Color color = _getPriorityColor(value);
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _priority = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag,
                size: 16, 
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTodo() {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Format time string if time is selected
    String? timeString;
    if (_selectedTime != null) {
      final hour = _selectedTime!.hour.toString().padLeft(2, '0');
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      timeString = '$hour:$minute';
    }

    // Create or update Todo object
    final todo = Todo(
      id: widget.existingTodo?.id,
      doctorId: widget.existingTodo?.doctorId ?? '',
      date: widget.selectedDate,
      title: title,
      description: _descriptionController.text.trim(),
      priority: _priority,
      completed: widget.existingTodo?.completed ?? false,
      time: timeString,
      createdAt: widget.existingTodo?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(todo);
    Navigator.pop(context);
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  String _getMonthName(int month) {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][month - 1];
  }
}