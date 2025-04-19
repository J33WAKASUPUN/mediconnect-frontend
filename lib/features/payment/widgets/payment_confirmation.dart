import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../core/models/appointment_model.dart';

class PaymentConfirmationSheet extends StatefulWidget {
  final Appointment appointment;
  final Function(String paymentMethod, String? transactionDetails) onConfirm;
  
  const PaymentConfirmationSheet({
    Key? key,
    required this.appointment,
    required this.onConfirm,
  }) : super(key: key);

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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text('Payment Confirmation', style: AppStyles.heading1),
          const SizedBox(height: 8),
          Text('Complete payment for your appointment with $doctorName', 
              style: AppStyles.bodyText1),
          const SizedBox(height: 24),
          
          // Payment Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Date', widget.appointment.formattedAppointmentDate),
                _buildInfoRow('Time', widget.appointment.timeSlot),
                _buildInfoRow('Doctor', doctorName),
                const Divider(),
                _buildInfoRow('Amount', 'Rs. ${widget.appointment.amount.toStringAsFixed(2)}',
                    isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Payment Method Selection
          Text('Select Payment Method', style: AppStyles.heading3),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _paymentMethods.map((String method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
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
          const SizedBox(height: 16),
          
          // Transaction Details (not visible for cash)
          if (_selectedPaymentMethod != 'Cash') ...[
            Text('Transaction Reference (Optional)', style: AppStyles.heading3),
            const SizedBox(height: 8),
            TextField(
              controller: _transactionController,
              decoration: const InputDecoration(
                hintText: 'Enter reference number or transaction ID',
                border: OutlineInputBorder(),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Payment'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal 
                ? AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)
                : AppStyles.bodyText2,
          ),
          Text(
            value,
            style: isTotal 
                ? AppStyles.heading3
                : AppStyles.bodyText1,
          ),
        ],
      ),
    );
  }
}