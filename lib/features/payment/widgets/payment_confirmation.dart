import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../core/models/appointment_model.dart';

class PaymentConfirmationSheet extends StatefulWidget {
  final Appointment appointment;
  final Function(String paymentMethod, String? transactionDetails) onConfirm;
  
  const PaymentConfirmationSheet({
    super.key,
    required this.appointment,
    required this.onConfirm,
  });

  @override
  _PaymentConfirmationSheetState createState() => _PaymentConfirmationSheetState();
}

class _PaymentConfirmationSheetState extends State<PaymentConfirmationSheet> {
  String _selectedPaymentMethod = 'Credit Card';
  final TextEditingController _transactionController = TextEditingController();
  bool _isProcessing = false;
  
  final List<String> _paymentMethods = [
    'Credit Card',
    'Bank Transfer',
    'Mobile Wallet',
    'Cash',
  ];

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = widget.appointment.doctorDetails != null
        ? 'Dr. ${widget.appointment.doctorDetails!['firstName']} ${widget.appointment.doctorDetails!['lastName']}'
        : 'Doctor';
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar for dragging
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Confirmation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Complete payment for your appointment with $doctorName',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
            
          const SizedBox(height: 24),
          
          // Payment Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'Date',
                  widget.appointment.formattedAppointmentDate,
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                
                _buildInfoRow(
                  'Time',
                  widget.appointment.timeSlot,
                  Icons.access_time,
                ),
                const SizedBox(height: 12),
                
                _buildInfoRow(
                  'Doctor',
                  doctorName,
                  Icons.person,
                ),
                
                const Divider(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Rs. ${widget.appointment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Method Selection
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: _paymentMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Row(
                    children: [
                      Icon(
                        method == 'Credit Card'
                            ? Icons.credit_card
                            : method == 'Bank Transfer'
                                ? Icons.account_balance
                                : method == 'Mobile Wallet'
                                    ? Icons.smartphone
                                    : Icons.payments,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(method),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPaymentMethod = newValue;
                  });
                }
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Transaction Details (not visible for cash)
          if (_selectedPaymentMethod != 'Cash') ...[
            const Text(
              'Transaction Reference (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _transactionController,
              decoration: InputDecoration(
                hintText: 'Enter reference number or transaction ID',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing 
                  ? null 
                  : () {
                      setState(() {
                        _isProcessing = true;
                      });
                      
                      widget.onConfirm(
                        _selectedPaymentMethod,
                        _transactionController.text.isEmpty 
                            ? null 
                            : _transactionController.text,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              ),
              child: _isProcessing 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Processing...'),
                      ],
                    )
                  : const Text('Confirm Payment'),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}