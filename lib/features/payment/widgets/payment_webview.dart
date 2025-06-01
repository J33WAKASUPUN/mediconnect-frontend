import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_indicator.dart';

class PaymentWebView extends StatefulWidget {
  final String initialUrl;
  final Function(String) onPaymentComplete;
  final VoidCallback onPaymentCancelled;

  const PaymentWebView({
    super.key,
    required this.initialUrl,
    required this.onPaymentComplete,
    required this.onPaymentCancelled,
  });

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _jsLoaded = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    try {
      _initWebView();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      print("Error initializing WebView: $e");
    }
  }

  void _initWebView() {
    try {
      print("Initializing WebView with URL: ${widget.initialUrl}");
      
      _controller = WebViewController();
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print("WebView loading page: $url");
              setState(() {
                _isLoading = true;
              });
              _handleUrlChange(url);
            },
            onPageFinished: (String url) {
              print("WebView finished loading page: $url");
              setState(() {
                _isLoading = false;
              });
              
              if (!_jsLoaded) {
                _injectJs();
                _jsLoaded = true;
              }
              
              _handleUrlChange(url);
            },
            onNavigationRequest: (NavigationRequest request) {
              print("WebView navigation request to: ${request.url}");
              final shouldNavigate = _handleUrlChange(request.url);
              print("Should navigate: $shouldNavigate");
              return shouldNavigate ? NavigationDecision.navigate : NavigationDecision.prevent;
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
              });
            },
          ),
        );
        
      // Load the URL last to ensure everything is set up
      _controller.loadRequest(Uri.parse(widget.initialUrl));
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      print("Failed to initialize WebView: $e");
    }
  }

  bool _handleUrlChange(String url) {
    print('WebView navigating to: $url');
    
    // Check for PayPal success URL
    if (url.contains('success') && url.contains('token=')) {
      // Extract PayPal parameters
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      
      if (token != null) {
        // Notify parent about successful payment
        widget.onPaymentComplete(token);
        return false; // Don't navigate to the success URL
      }
    }
    
    // Check for PayPal cancel URL
    if (url.contains('cancel') && url.contains('token=')) {
      widget.onPaymentCancelled();
      return false; // Don't navigate to the cancel URL
    }
    
    return true; // Allow navigation
  }

  void _injectJs() {
    try {
      // Inject JavaScript to monitor URL changes
      _controller.runJavaScript('''
        (function() {
          var pushState = history.pushState;
          history.pushState = function(state, title, url) {
            pushState.apply(history, arguments);
            window.dispatchEvent(new CustomEvent('locationchange', {
              detail: { url: url }
            }));
          };
          
          window.addEventListener('popstate', function() {
            window.dispatchEvent(new CustomEvent('locationchange', {
              detail: { url: document.location.href }
            }));
          });
        })();
      ''');
    } catch (e) {
      print("Failed to inject JavaScript: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Show error view with retry option
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline, 
                    size: 64, 
                    color: Colors.red
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to load payment page',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                      _isLoading = true;
                    });
                    try {
                      _initWebView();
                    } catch (e) {
                      setState(() {
                        _hasError = true;
                        _errorMessage = e.toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Payment'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: widget.onPaymentCancelled,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Only show WebViewWidget if we've properly initialized
        if (!_hasError) WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Loading PayPal checkout...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onPaymentCancelled,
                color: Colors.grey[800],
                tooltip: 'Cancel Payment',
              ),
            ),
          ),
        ),
      ],
    );
  }
}