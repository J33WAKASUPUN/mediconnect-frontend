import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/payment/providers/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/models/appointment_model.dart';
import '../widgets/payment_webview.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appointment;

  const PaymentScreen({
    super.key,
    required this.appointment,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _isWebViewSupported = true;

  // Always use the fixed consultation fee of 2500
  double get appointmentFee => 2500;

  // Get doctor name from appointment
  String get doctorName {
    if (widget.appointment.doctorDetails != null) {
      return 'Dr. ${widget.appointment.doctorDetails!['firstName']} ${widget.appointment.doctorDetails!['lastName']}';
    }
    return 'Doctor';
  }

  // Get appointment reason
  String get appointmentReason {
    return widget.appointment.reason;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false).setContext(context);
    });
    // Check if WebView is supported
    try {
      // This will throw an exception if WebView is not supported
      if (kIsWeb) {
        // WebView not fully supported in web yet
        _isWebViewSupported = false;
      }
    } catch (e) {
      print("WebView not supported: $e");
      _isWebViewSupported = false;
    }
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
          : Consumer<PaymentProvider>(
              builder: (context, provider, _) {
                // Show PayPal WebView if we have an approval URL and WebView is supported
                if (provider.paypalApprovalUrl != null && _isWebViewSupported) {
                  try {
                    return PaymentWebView(
                      initialUrl: provider.paypalApprovalUrl!,
                      onPaymentComplete: _handlePaymentComplete,
                      onPaymentCancelled: _handlePaymentCancelled,
                    );
                  } catch (e) {
                    print("WebView error: $e");
                    // If WebView fails, fall back to browser option
                    _isWebViewSupported = false;
                  }
                }

                // Show browser option if WebView is not supported but we have PayPal URL
                if (provider.paypalApprovalUrl != null &&
                    !_isWebViewSupported) {
                  return _buildBrowserPaymentOption(
                      provider.paypalApprovalUrl!, provider.currentOrderId);
                }

                // Otherwise show payment info
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppointmentSummary(),
                      const SizedBox(height: 24),
                      const Text(
                        'Payment Method',
                        style: AppStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentMethodCard(
                        icon: Icons.payment,
                        title: 'PayPal',
                        subtitle: 'Pay securely via PayPal',
                        isSelected: true,
                      ),
                      const SizedBox(height: 32),
                      if (provider.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: AppColors.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  provider.error!,
                                  style:
                                      const TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _isWebViewSupported
                              ? 'Pay with PayPal'
                              : 'Pay with PayPal in Browser',
                          onPressed: _initiatePayment,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // New method to build browser payment option
  Widget _buildBrowserPaymentOption(String paypalUrl, String? orderId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_browser, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Complete Payment in Browser',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Please complete your payment in your web browser:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.language),
              label: const Text('Open PayPal in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => _openBrowser(paypalUrl),
            ),
            const SizedBox(height: 30),
            const Text(
              'After completing payment in your browser, return here and confirm:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('I\'ve Completed Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: orderId != null
                  ? () => _handlePaymentComplete(orderId)
                  : null,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _handlePaymentCancelled,
              child: const Text('Cancel Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // Method to open PayPal in browser
  Future<void> _openBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch browser')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening browser: $e')),
      );
    }
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
            _buildInfoRow(
                'Date', _formatDate(widget.appointment.appointmentDate)),
            _buildInfoRow('Time', widget.appointment.timeSlot),
            _buildInfoRow('Reason', appointmentReason),
            const Divider(height: 24),
            _buildInfoRow(
                'Consultation Fee', 'Rs. ${appointmentFee.toStringAsFixed(2)}',
                isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.subtitle1,
                  ),
                  Text(
                    subtitle,
                    style: AppStyles.bodyText2,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
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
            style: isTotal
                ? AppStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)
                : AppStyles.bodyText1,
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

  Future<void> _initiatePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print("Initiating payment for appointment: ${widget.appointment.id}");
      final response =
          await Provider.of<PaymentProvider>(context, listen: false)
              .createPaymentOrder(
        appointmentId: widget.appointment.id,
        amount: appointmentFee,
      );

      print("Payment initiation response: $response");
      print(
          "PayPal approval URL: ${Provider.of<PaymentProvider>(context, listen: false).paypalApprovalUrl}");

      // The state will be updated by Consumer widget when paypalApprovalUrl is set

      if (!mounted) return;

      // If we're still in processing state after provider update, something went wrong
      if (_isProcessing) {
        setState(() {
          _isProcessing = false;
        });

        // Show error message
        final provider = Provider.of<PaymentProvider>(context, listen: false);
        if (provider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${provider.error}')),
          );
        } else if (provider.paypalApprovalUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get PayPal approval URL')),
          );
        }
      }
    } catch (e) {
      print("Error initiating payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handlePaymentComplete(String orderId) async {
  setState(() {
    _isProcessing = true;
  });

  try {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final success = await paymentProvider.capturePayment();

    if (success) {
      // Register the payment locally if not already done
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      if (!appointmentProvider.hasLocalPayment(widget.appointment.id)) {
        appointmentProvider.registerPaymentForAppointment(
          widget.appointment.id, 
          orderId
        );
      }
      
      // Force refresh the appointment list
      await appointmentProvider.loadAppointments();

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Payment Successful'),
            content: const Text(
                'Your payment was processed successfully. You will receive a confirmation email shortly.'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(paymentProvider.error ?? 'Payment verification failed')),
      );

      setState(() {
        _isProcessing = false;
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );

    setState(() {
      _isProcessing = false;
    });
  }
}

  void _handlePaymentCancelled() {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.resetPaymentProcess();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment was cancelled')),
    );

    setState(() {
      _isProcessing = false;
    });
  }
}
