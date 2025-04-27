// // lib/features/payment/screens/receipt_viewer_screen.dart

// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:mediconnect/config/api_endpoints.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:mediconnect/core/services/api_service.dart';
// import '../../../shared/constants/colors.dart';
// import '../../../shared/widgets/loading_indicator.dart';
// import 'package:provider/provider.dart';

// class ReceiptViewerScreen extends StatefulWidget {
//   final String paymentId;
//   final String paymentReference;

//   const ReceiptViewerScreen({
//     Key? key,
//     required this.paymentId,
//     required this.paymentReference,
//   }) : super(key: key);

//   @override
//   _ReceiptViewerScreenState createState() => _ReceiptViewerScreenState();
// }

// class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
//   late WebViewController _controller;
//   bool _isLoading = true;
//   bool _loadError = false;
//   String? _errorMessage;
  
//   @override
//   void initState() {
//     super.initState();
//     _setupWebView();
//   }
  
//   void _setupWebView() async {
//     final apiService = Provider.of<ApiService>(context, listen: false);
    
//     try {
//       // Get token for authentication
//       final token = await apiService.getStorageService().getToken();
//       final receiptUrl = '${ApiEndpoints.baseUrl}${ApiEndpoints.payments}/${widget.paymentId}/receipt';
      
//       setState(() {
//         _isLoading = true;
//         _loadError = false;
//         _errorMessage = null;
//       });
      
//       // Create a WebViewController with the URL and auth header
//       _controller = WebViewController()
//         ..setJavaScriptMode(JavaScriptMode.unrestricted)
//         ..setNavigationDelegate(
//           NavigationDelegate(
//             onPageStarted: (String url) {
//               print('Receipt page started loading: $url');
//             },
//             onPageFinished: (String url) {
//               print('Receipt page finished loading: $url');
//               setState(() {
//                 _isLoading = false;
//               });
//             },
//             onWebResourceError: (WebResourceError error) {
//               print('Receipt page error: ${error.description}');
//               setState(() {
//                 _isLoading = false;
//                 _loadError = true;
//                 _errorMessage = error.description;
//               });
//             },
//           ),
//         )
//         ..loadRequest(
//           Uri.parse(receiptUrl),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Accept': 'application/pdf',
//           },
//         );
        
//     } catch (e) {
//       print('Error setting up receipt viewer: $e');
//       setState(() {
//         _isLoading = false;
//         _loadError = true;
//         _errorMessage = e.toString();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Payment Receipt'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _setupWebView,
//             tooltip: 'Reload',
//           ),
//         ],
//       ),
//       body: _buildContent(),
//     );
//   }

//   Widget _buildContent() {
//     if (_isLoading) {
//       return const LoadingIndicator(message: 'Loading receipt...');
//     }
    
//     if (_loadError) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Colors.red,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Error loading receipt',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 32),
//               child: Text(
//                 _errorMessage ?? 'An unknown error occurred',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _setupWebView,
//               child: const Text('Try Again'),
//             ),
//           ],
//         ),
//       );
//     }
    
//     // Show the PDF in a WebView
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(8),
//           color: AppColors.primary.withOpacity(0.1),
//           child: Row(
//             children: [
//               Icon(Icons.info_outline, size: 16, color: AppColors.primary),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'Payment Reference: ${widget.paymentReference}',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: WebViewWidget(controller: _controller),
//         ),
//       ],
//     );
//   }
// }