// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../../shared/constants/colors.dart';
// import '../../shared/widgets/loading_indicator.dart';

// class WebViewScreen extends StatefulWidget {
//   final String title;
//   final String url;
//   final String? additionalInfo;

//   const WebViewScreen({
//     Key? key,
//     required this.title,
//     required this.url,
//     this.additionalInfo,
//   }) : super(key: key);

//   @override
//   _WebViewScreenState createState() => _WebViewScreenState();
// }

// class _WebViewScreenState extends State<WebViewScreen> {
//   late WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _setupWebView();
//   }

//   void _setupWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             setState(() {
//               _isLoading = true;
//             });
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               _isLoading = false;
//             });
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.url));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => _controller.reload(),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (widget.additionalInfo != null)
//             Container(
//               padding: EdgeInsets.all(8),
//               color: AppColors.primary.withOpacity(0.1),
//               width: double.infinity,
//               child: Text(
//                 widget.additionalInfo!,
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//           Expanded(
//             child: Stack(
//               children: [
//                 WebViewWidget(controller: _controller),
//                 if (_isLoading)
//                   const Center(
//                     child: LoadingIndicator(message: 'Loading content...'),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }