import 'package:flutter/material.dart';
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
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog title
              Text(
                _isEditing ? 'Edit Task' : 'Add New Task',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              
              // Priority selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Priority',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityOption('Low', 'low'),
                      const SizedBox(width: 8),
                      _buildPriorityOption('Medium', 'medium'),
                      const SizedBox(width: 8),
                      _buildPriorityOption('High', 'high'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Time selection
              Row(
                children: [
                  const Text(
                    'Time (optional): ',
                    style: TextStyle(fontSize: 16),
                  ),
                  Expanded(
                    child: _selectedTime != null
                        ? Text(
                            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          )
                        : const Text(
                            'Not set',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.access_time,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _selectTime,
                  ),
                  if (_selectedTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _selectedTime = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveTodo,
                    child: Text(_isEditing ? 'Update' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
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
            color: isSelected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
        const SnackBar(content: Text('Please enter a title')),
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
}