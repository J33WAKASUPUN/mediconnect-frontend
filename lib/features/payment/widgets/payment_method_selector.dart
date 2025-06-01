import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';

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
        Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildPaymentOption(
          PaymentMethodType.creditCard,
          'Credit/Debit Card',
          Icons.credit_card,
          'Pay securely with your card',
        ),
        
        _buildPaymentOption(
          PaymentMethodType.bankTransfer,
          'Bank Transfer',
          Icons.account_balance,
          'Direct transfer from your bank account',
        ),
        
        _buildPaymentOption(
          PaymentMethodType.mobileWallet,
          'Mobile Wallet',
          Icons.smartphone,
          'Pay using digital wallets like PhonePe, PayTM',
        ),
        
        _buildPaymentOption(
          PaymentMethodType.cash,
          'Cash (Pay at Clinic)',
          Icons.payments,
          'Pay cash during your appointment',
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    PaymentMethodType method, 
    String title, 
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedMethod == method;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          )
        ] : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
          widget.onSelect(method);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}