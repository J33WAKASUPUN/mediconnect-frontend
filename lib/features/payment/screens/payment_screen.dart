import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/models/appointment_model.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appointment;
  
  const PaymentScreen({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = ['Credit Card', 'Debit Card', 'Mobile Payment'];

  // Get appointment amount
  double get appointmentFee {
    return widget.appointment.amount;
  }
  
  // Get doctor name from appointment
  String get doctorName {
    if (widget.appointment.doctorDetails != null) {
      return 'Dr. ${widget.appointment.doctorDetails!['firstName']} ${widget.appointment.doctorDetails!['lastName']}';
    }
    return 'Doctor';
  }
  
  // Get appointment reason as type
  String get appointmentType {
    return widget.appointment.reason;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: _isProcessing
          ? const LoadingIndicator(message: 'Processing payment...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppointmentSummary(),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSelection(),
                  const SizedBox(height: 24),
                  _buildPaymentDetails(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, // Make button full width
                    child: CustomButton(
                      text: 'Pay Now',
                      onPressed: _processPayment,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppointmentSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appointment Summary', style: AppStyles.heading2),
            const Divider(height: 24),
            _buildInfoRow('Doctor', doctorName),
            _buildInfoRow('Date', _formatDate(widget.appointment.appointmentDate)),
            _buildInfoRow('Time', widget.appointment.timeSlot),
            _buildInfoRow('Reason', appointmentType),
            const Divider(height: 24),
            _buildInfoRow('Consultation Fee', '\$${appointmentFee.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Payment Method', style: AppStyles.heading2),
        const SizedBox(height: 16),
        ...List.generate(
          _paymentMethods.length,
          (index) => RadioListTile<String>(
            title: Text(_paymentMethods[index]),
            value: _paymentMethods[index],
            groupValue: _selectedPaymentMethod,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    if (_selectedPaymentMethod == null) {
      return const SizedBox.shrink();
    }

    // Show different forms based on selected payment method
    switch (_selectedPaymentMethod) {
      case 'Credit Card':
      case 'Debit Card':
        return _buildCardPaymentForm();
      case 'Mobile Payment':
        return _buildMobilePaymentForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Card Details', style: AppStyles.heading2),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: 'XXXX XXXX XXXX XXXX',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: 'XXX',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'Name as appears on card',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile Payment', style: AppStyles.heading2),
        const SizedBox(height: 16),
        const Center(
          child: Icon(
            Icons.qr_code,
            size: 200,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Scan this QR code with your mobile payment app',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold) : AppStyles.bodyText1,
          ),
          Text(
            value,
            style: isTotal
                ? AppStyles.heading1.copyWith(color: AppColors.primary)
                : AppStyles.bodyText1,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Your payment was processed successfully. You will receive a confirmation email shortly.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}