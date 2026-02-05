// // Example: How to integrate Order History module
// // This file demonstrates how to use the order history module in your app
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'order_history.dart';
//
// class ExampleOrderHistoryIntegration extends StatelessWidget {
//   const ExampleOrderHistoryIntegration({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Order History Integration'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Order History Module Integration Example',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             // Basic Navigation Button
//             ElevatedButton(
//               onPressed: () {
//                 // Navigate to order history screen
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const OrderHistoryScreen(),
//                   ),
//                 );
//               },
//               child: const Text('Navigate to Order History'),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Advanced Features List
//             const Text(
//               'Features Available:',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//
//             const Bullet(
//               '• Complete order history with pagination',
//               style: TextStyle(fontSize: 14),
//             ),
//             const Bullet(
//               '• Advanced filtering by status, date range, search',
//               style: TextStyle(fontSize: 14),
//             ),
//             const Bullet(
//               '• Real-time search functionality',
//               style: TextStyle(fontSize: 14),
//             ),
//             const Bullet(
//               '• Statistics dashboard with revenue insights',
//               style: TextStyle(fontSize: 14),
//             ),
//             const Bullet(
//               '• Detailed order information modals',
//               style: TextStyle(fontSize: 14),
//             ),
//             const Bullet(
//               '• Pull-to-refresh and load more functionality',
//               style: TextStyle(fontSize: 14),
//             ),
//             const Bullet(
//               '• Responsive design for all screen sizes',
//               style: TextStyle(fontSize: 14),
//             ),
//             const Bullet(
//               '• Modern Material Design with gradients and shadows',
//               style: TextStyle(fontSize: 14),
//             ),
//
//             const SizedBox(height: 24),
//
//             // API Integration Example
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'API Integration:',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Bullet(
//                     '• GET /orders/history/{outletId}',
//                     style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
//                   ),
//                   const Bullet(
//                     '• GET /orders/history/{outletId}?from={from}&to={to}',
//                     style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
//                   ),
//                   const Bullet(
//                     '• GET /orders/history/{outletId}/summary',
//                     style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
//                   ),
//                   const Bullet(
//                     '• GET /orders/history/{outletId}?search={query}',
//                     style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Usage Code
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Usage:',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       '''
// // 1. Import the module
// import 'package:restro/features/order_history/order_history.dart';
//
// // 2. Navigate to the screen
// Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryScreen()));
//
// // 3. Access order history data
// final orderHistoryState = ref.watch(orderHistoryAsyncProvider);
// final orders = ref.watch(ordersProvider);
// final summary = ref.watch(orderHistorySummaryProvider);
//
// // 4. Use the data
// print('Total orders: \${orders.length}');
// print('Summary available: \${summary != null}');
// print('Loading: \${orderHistoryState.isLoading}');
//
// // 5. Advanced usage with filters
// ref.read(orderHistoryProvider.notifier).filterByStatus('completed');
// ref.read(orderHistoryProvider.notifier).filterByDateRange(
//   DateTime.now().subtract(const Duration(days: 7)),
//   DateTime.now(),
// );
//
// // 6. Search functionality
// ref.read(orderHistoryProvider.notifier).searchOrders('customer name');
//                       ''',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontFamily: 'monospace',
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
