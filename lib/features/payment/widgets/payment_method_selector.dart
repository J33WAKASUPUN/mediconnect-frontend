import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

enum PaymentMethodType {
  creditCard,
  bankTransfer,
  mobileWallet,
  cash
}

class PaymentMethodSelector extends StatefulWidget {
  final Function(PaymentMethodType) onSelect;
  final PaymentMethodType? initialSelection;

  const PaymentMethodSelector({
    super.key,
    required this.onSelect,
    this.initialSelection,
  });

  @override
  _PaymentMethodSelectorState createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethodType? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(          'Select Payment Method',
          style: AppStyles.subtitle1,
        ),
        const SizedBox(height: 16),
        
        _buildPaymentOption(
          PaymentMethodType.creditCard,
          'Credit/Debit Card',
          Icons.credit_card,
        ),
        
        _buildPaymentOption(
          PaymentMethodType.bankTransfer,
          'Bank Transfer',
          Icons.account_balance,
        ),
        
        _buildPaymentOption(
          PaymentMethodType.mobileWallet,
          'Mobile Wallet',
          Icons.smartphone,
        ),
        
        _buildPaymentOption(
          PaymentMethodType.cash,
          'Cash (Pay at Clinic)',
          Icons.payments,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    PaymentMethodType method, 
    String title, 
    IconData icon
  ) {
    final isSelected = _selectedMethod == method;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
          widget.onSelect(method);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : Colors.black,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}