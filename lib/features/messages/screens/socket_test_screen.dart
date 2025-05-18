// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:mediconnect/core/services/socket_service.dart';
// import 'package:mediconnect/features/auth/providers/auth_provider.dart';
// import 'package:provider/provider.dart';

// class SocketTestScreen extends StatefulWidget {
//   static const routeName = '/socket-test';

//   @override
//   _SocketTestScreenState createState() => _SocketTestScreenState();
// }

// class _SocketTestScreenState extends State<SocketTestScreen> {
//   final TextEditingController _eventController = TextEditingController();
//   final TextEditingController _dataController = TextEditingController();
//   final ScrollController _logController = ScrollController();
//   final List<String> _logs = [];
//   bool _isConnected = false;
  
//   @override
//   void initState() {
//     super.initState();
//     _checkSocketConnection();
//     _addLog("Socket Test Screen initialized");
//   }
  
//   void _checkSocketConnection() {
//     final socketService = SocketService();
//     setState(() {
//       _isConnected = socketService.hasConnection();
//     });
//     _addLog("Initial connection status: ${_isConnected ? 'Connected' : 'Disconnected'}");
    
//     socketService.connectionState.listen((connected) {
//       if (mounted) {
//         setState(() {
//           _isConnected = connected;
//         });
//         _addLog(connected ? "Socket connected" : "Socket disconnected");
//       }
//     });
//   }
  
//   void _addLog(String message) {
//     setState(() {
//       _logs.add("[${DateTime.now().toString().substring(11, 19)}] $message");
//     });
    
//     Future.delayed(Duration(milliseconds: 100), () {
//       if (_logController.hasClients) {
//         _logController.animateTo(
//           _logController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
  
//   void _reconnect() {
//     _addLog("Attempting to reconnect...");
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     if (authProvider.token != null) {
//       SocketService().initialize(authProvider.token!);
//     } else {
//       _addLog("No auth token available!");
//     }
//   }
  
//   void _disconnect() {
//     _addLog("Manually disconnecting...");
//     SocketService().disconnect();
//   }
  
//   void _emitEvent() {
//     if (_eventController.text.isEmpty) {
//       _addLog("Please enter an event name");
//       return;
//     }
    
//     final socketService = SocketService();
//     if (!socketService.hasConnection()) {
//       _addLog("Socket not connected. Cannot emit event.");
//       return;
//     }
    
//     try {
//       Map<String, dynamic> data = {};
//       if (_dataController.text.isNotEmpty) {
//         try {
//           data = Map<String, dynamic>.from(
//             jsonDecode(_dataController.text)
//           );
//         } catch (e) {
//           _addLog("Error parsing JSON data: $e");
//           return;
//         }
//       }
      
//       _addLog("Emitting event: ${_eventController.text} with data: $data");
//       // Using custom emit method instead of direct socket access
//       socketService.emitEvent(_eventController.text, data);
//     } catch (e) {
//       _addLog("Error: $e");
//     }
//   }
  
//   void _testJoinConversation() {
//     _addLog("Testing joinConversation...");
//     SocketService().joinConversation("test-conversation-id");
//   }

//   void _callServerTest() {
//     _addLog("Calling server socket test endpoint...");
//     // This would require an HTTP client, you can implement this with your API service
//     _addLog("Note: This requires HTTP implementation, check server logs");
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Socket Testing"),
//         actions: [
//           Container(
//             padding: EdgeInsets.all(8),
//             child: Center(
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: _isConnected ? Colors.green : Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   _isConnected ? "Connected" : "Disconnected",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _reconnect,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                     ),
//                     child: Text("Reconnect"),
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _disconnect,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                     ),
//                     child: Text("Disconnect"),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _testJoinConversation,
//                     child: Text("Test Join Conversation"),
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _callServerTest,
//                     child: Text("Server Socket Test"),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _eventController,
//               decoration: InputDecoration(
//                 labelText: "Event Name",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: _dataController,
//               decoration: InputDecoration(
//                 labelText: "Data (JSON)",
//                 border: OutlineInputBorder(),
//                 hintText: '{"key": "value"}',
//               ),
//               maxLines: 3,
//             ),
//             SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _emitEvent,
//               child: Text("Emit Event"),
//             ),
//             SizedBox(height: 16),
//             Text("Logs:", style: TextStyle(fontWeight: FontWeight.bold)),
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.black,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: ListView.builder(
//                   controller: _logController,
//                   itemCount: _logs.length,
//                   itemBuilder: (context, index) {
//                     return Text(
//                       _logs[index],
//                       style: TextStyle(
//                         color: _logs[index].contains("Error") ? Colors.red : 
//                                _logs[index].contains("connected") ? Colors.green : 
//                                Colors.white,
//                         fontFamily: 'monospace',
//                         fontSize: 12,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }