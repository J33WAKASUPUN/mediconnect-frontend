import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';

enum AppointmentAction { confirm, cancel }

class DoctorAppointmentActionDialog extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final DateTime appointmentDate; 
  final AppointmentAction actionType;
  
  const DoctorAppointmentActionDialog({
    super.key,
    required this.appointmentId,
    required this.patientName,
    required this.appointmentDate,
    required this.actionType,
  });

  @override
  _DoctorAppointmentActionDialogState createState() => _DoctorAppointmentActionDialogState();
}

class _DoctorAppointmentActionDialogState extends State<DoctorAppointmentActionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final List<String> _cancellationReasons = [
    'Schedule conflict',
    'Unavailable at scheduled time',
    'Medical emergency',
    'Patient requested',
    'Other'
  ];
  
  String _selectedReason = 'Schedule conflict';
  bool _customReason = false;
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirming = widget.actionType == AppointmentAction.confirm;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConfirming ? Icons.check_circle : Icons.warning_rounded,
                  color: isConfirming ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isConfirming ? 'Confirm Appointment' : 'Cancel Appointment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isConfirming 
                ? 'Are you sure you want to confirm the appointment with ${widget.patientName} on ${_formatDate(widget.appointmentDate)}?'
                : 'Are you sure you want to cancel the appointment with ${widget.patientName} on ${_formatDate(widget.appointmentDate)}?',
              style: TextStyle(fontSize: 16),
            ),
            
            // For cancellation only, add reason selection
            if (!isConfirming) ...[
              const SizedBox(height: 24),
              Text(
                'Please select a reason for cancellation:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Predefined reasons
              if (!_customReason) ...[
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _cancellationReasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                      if (value == 'Other') {
                        _customReason = true;
                      }
                    });
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Please specify your reason',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _customReason = false;
                          _selectedReason = 'Schedule conflict';
                        });
                      },
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ],
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Get the reason text - for confirm, just pass empty string as we don't need notes
                    String reason = isConfirming ? "" : 
                                   (_customReason ? _reasonController.text.trim() : _selectedReason);
                    
                    // Return the action result with reason
                    Navigator.of(context).pop({
                      'confirmed': true,
                      'reason': reason,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirming ? AppColors.primary : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isConfirming ? 'Confirm' : 'Cancel Appointment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}