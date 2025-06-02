import 'package:flutter/material.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import '../../../core/models/todo_model.dart';

class TodoListItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoListItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(todo.priority);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: todo.completed ? Colors.grey.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Checkbox
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: todo.completed ? Colors.green : Colors.grey.shade400,
                              width: 2,
                            ),
                            color: todo.completed ? Colors.green : Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: todo.completed ? Colors.white : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Title with strikethrough if completed
                Expanded(
                  child: Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: todo.completed ? TextDecoration.lineThrough : null,
                      color: todo.completed ? Colors.grey.shade500 : Colors.black87,
                    ),
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.primary,
                      onPressed: onEdit,
                      tooltip: 'Edit task',
                    ),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red.shade400,
                      onPressed: onDelete,
                      tooltip: 'Delete task',
                    ),
                  ],
                ),
              ],
            ),
            
            // Description (if any)
            if (todo.description != null && todo.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, right: 8, top: 4),
                child: Text(
                  todo.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: todo.completed ? Colors.grey.shade500 : Colors.grey.shade700,
                    decoration: todo.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            
            // Labels row
            Padding(
              padding: const EdgeInsets.only(left: 44, right: 8, top: 8),
              child: Row(
                children: [
                  // Priority label
                  _buildLabel(
                    icon: Icons.flag,
                    text: todo.priority.toUpperCase(),
                    color: priorityColor,
                  ),
                  const SizedBox(width: 8),
                  
                  // Time label (if any)
                  if (todo.time != null && todo.time!.isNotEmpty)
                    _buildLabel(
                      icon: Icons.access_time,
                      text: todo.time!,
                      color: Colors.blue,
                    ),

                  // Completed label
                  if (todo.completed)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildLabel(
                        icon: Icons.check_circle_outline,
                        text: 'COMPLETED',
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLabel({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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