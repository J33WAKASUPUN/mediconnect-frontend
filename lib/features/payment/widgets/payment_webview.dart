// lib/features/payment/widgets/payment_webview.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load payment page',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
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
                child: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onPaymentCancelled,
                child: const Text('Cancel Payment'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Only show WebViewWidget if we've properly initialized
        if (!_hasError) WebViewWidget(controller: _controller),
        if (_isLoading)
          const LoadingIndicator(message: 'Loading PayPal checkout...'),
        Positioned(
          top: 10,
          right: 10,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onPaymentCancelled,
              color: Colors.grey[800],
              tooltip: 'Cancel Payment',
            ),
          ),
        ),
      ],
    );
  }
}