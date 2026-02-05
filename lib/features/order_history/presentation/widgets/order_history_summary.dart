import 'package:flutter/material.dart';
import '../../domain/entities/order_history_entity.dart';

class OrderHistorySummary extends StatelessWidget {
  final OrderHistorySummaryEntity summary;

  const OrderHistorySummary({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Main Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D3748), Color(0xFF1A365)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total Orders',
                      summary.totalOrders.toString(),
                      Icons.receipt_long,
                      Color(0xFF2D3748),
                    ),
                    _buildSummaryItem(
                      'Revenue',
                      summary.formattedRevenue,
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildSummaryItem(
                      'Avg. Order',
                      summary.formattedAverageOrderValue,
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Completed',
                      '${summary.completedOrders}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildSummaryItem(
                      'Cancelled',
                      '${summary.cancelledOrders}',
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2D3748),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completion Rate: ${summary.completionRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )],

      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
