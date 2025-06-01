import 'package:flutter/material.dart';
import 'package:mediconnect/features/appointment/providers/appointment_provider.dart';
import 'package:mediconnect/features/payment/providers/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/constants/colors.dart';
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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                return Column(
                  children: [
                    // Header section
                    Container(
                      color: AppColors.primary,
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete Your Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose your preferred payment method',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Main content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAppointmentSummary(),
                            const SizedBox(height: 24),
                            
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildPaymentMethodCard(),
                            
                            const SizedBox(height: 24),
                            
                            if (provider.error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        provider.error!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.payment),
                                label: Text(_isWebViewSupported
                                    ? 'Pay with PayPal'
                                    : 'Pay with PayPal in Browser'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
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
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Complete Payment in Browser',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'You will be redirected to PayPal to complete your payment securely.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.language),
              label: const Text('Open PayPal in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openBrowser(paypalUrl),
            ),
            const SizedBox(height: 30),
            const Text(
              'After completing payment, return here to confirm:',
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
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: orderId != null
                  ? () => _handlePaymentComplete(orderId)
                  : null,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Payment'),
              onPressed: _handlePaymentCancelled,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
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
          SnackBar(
            content: const Text('Could not launch browser'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening browser: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildAppointmentSummary() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Appointment Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
              child: Image.asset(
                'assets/images/paypal_logo.png',
                width: 24,
                height: 24,
                // Use an icon if image is not available
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.payment,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'PayPal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pay securely via PayPal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: AppColors.primary,
            ),
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
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: isTotal
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  )
                : const TextStyle(fontWeight: FontWeight.w500),
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
      final response =
          await Provider.of<PaymentProvider>(context, listen: false)
              .createPaymentOrder(
        appointmentId: widget.appointment.id,
        amount: appointmentFee,
      );

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
            SnackBar(
              content: Text('Error: ${provider.error}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (provider.paypalApprovalUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not get PayPal approval URL'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your payment was processed successfully. You will receive a confirmation email shortly.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Return to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.error ?? 'Payment verification failed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
      SnackBar(
        content: const Text('Payment was cancelled'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    setState(() {
      _isProcessing = false;
    });
  }
}