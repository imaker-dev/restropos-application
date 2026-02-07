import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/report_item_model.dart';
import '../../data/model/report_details_model.dart' as details;

class ReportDetailsScreen extends StatefulWidget {
  final ReportItem reportItem;
  final String? selectedRange;

  const ReportDetailsScreen({
    super.key,
    required this.reportItem,
    this.selectedRange,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late details.ReportDetails reportDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    // Simulate API call to get detailed report data
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      reportDetails = _generateMockReportDetails(widget.reportItem);
      isLoading = false;
    });
  }

  details.ReportDetails _generateMockReportDetails(ReportItem reportItem) {
    final now = DateTime.now();
    
    return details.ReportDetails(
      id: reportItem.id,
      title: reportItem.title,
      date: reportItem.date,
      generatedAt: now,
      rangeKey: reportItem.rangeKey,
      summary: details.ReportSummary(
        totalOrders: reportItem.orders,
        totalRevenue: reportItem.amount,
        averageOrderValue: reportItem.amount / reportItem.orders,
        totalItems: reportItem.orders * 3, // Mock calculation
        taxAmount: reportItem.amount * 0.18, // 18% GST
        discountAmount: reportItem.amount * 0.05, // 5% discount
        cancelledOrders: (reportItem.orders * 0.02).round(), // 2% cancelled
        paymentMethods: {
          'Cash': (reportItem.orders * 0.3).round(),
          'Card': (reportItem.orders * 0.5).round(),
          'UPI': (reportItem.orders * 0.2).round(),
        },
      ),
      items: _generateMockReportItems(),
      charts: _generateMockCharts(),
      metadata: {
        'generatedBy': 'System',
        'format': 'PDF',
        'size': '2.4 MB',
      },
    );
  }

  List<details.ReportItem> _generateMockReportItems() {
    return [
      const details.ReportItem(
        name: 'Burger',
        quantity: 45,
        revenue: 2250.0,
        percentage: 25.0,
      ),
      const details.ReportItem(
        name: 'Pizza',
        quantity: 32,
        revenue: 1920.0,
        percentage: 20.0,
      ),
      const details.ReportItem(
        name: 'Pasta',
        quantity: 28,
        revenue: 1680.0,
        percentage: 18.0,
      ),
      const details.ReportItem(
        name: 'Sandwich',
        quantity: 25,
        revenue: 1250.0,
        percentage: 15.0,
      ),
      const details.ReportItem(
        name: 'Salad',
        quantity: 20,
        revenue: 800.0,
        percentage: 12.0,
      ),
      const details.ReportItem(
        name: 'Beverages',
        quantity: 50,
        revenue: 1000.0,
        percentage: 10.0,
      ),
    ];
  }

  List<details.ReportChart> _generateMockCharts() {
    return [
      details.ReportChart(
        type: 'pie',
        title: 'Sales by Category',
        data: [
          const details.ChartData(label: 'Food', value: 65.0, category: 'main'),
          const details.ChartData(label: 'Beverages', value: 25.0, category: 'drinks'),
          const details.ChartData(label: 'Desserts', value: 10.0, category: 'desserts'),
        ],
      ),
      details.ReportChart(
        type: 'bar',
        title: 'Daily Sales',
        data: [
          const details.ChartData(label: 'Mon', value: 1200.0),
          const details.ChartData(label: 'Tue', value: 1500.0),
          const details.ChartData(label: 'Wed', value: 1800.0),
          const details.ChartData(label: 'Thu', value: 1400.0),
          const details.ChartData(label: 'Fri', value: 2100.0),
          const details.ChartData(label: 'Sat', value: 2500.0),
          const details.ChartData(label: 'Sun', value: 2200.0),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.reportItem.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReport,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportHeader(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTopItemsSection(),
                  const SizedBox(height: 24),
                  _buildPaymentMethodsSection(),
                  const SizedBox(height: 24),
                  _buildChartsSection(),
                  const SizedBox(height: 24),
                  _buildMetadataSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.insert_chart_outlined,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reportItem.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generated on ${reportDetails.generatedAt?.day}/${reportDetails.generatedAt?.month}/${reportDetails.generatedAt?.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip('Range', widget.reportItem.rangeKey),
              const SizedBox(width: 8),
              if (widget.reportItem.status != null)
                _buildInfoChip('Status', widget.reportItem.status!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(widget.reportItem.status ?? '').withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildSummaryCard(
              'Total Orders',
              reportDetails.summary.totalOrders.toString(),
              Icons.receipt_long,
              Colors.blue.shade600,
            ),
            _buildSummaryCard(
              'Revenue',
              '₹${reportDetails.summary.totalRevenue.toStringAsFixed(0)}',
              Icons.currency_rupee,
              Colors.green.shade600,
            ),
            _buildSummaryCard(
              'Avg Order Value',
              '₹${reportDetails.summary.averageOrderValue.toStringAsFixed(0)}',
              Icons.trending_up,
              Colors.orange.shade600,
            ),
            _buildSummaryCard(
              'Total Items',
              reportDetails.summary.totalItems.toString(),
              Icons.shopping_bag,
              Colors.purple.shade600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Selling Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: reportDetails.items
                .take(5)
                .map((item) => _buildItemRow(item))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(details.ReportItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.quantity} sold',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.revenue.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${item.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: reportDetails.summary.paymentMethods.entries
                .map((entry) => _buildPaymentRow(entry.key, entry.value))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String method, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            _getPaymentIcon(method),
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              method,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count orders',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Charts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...reportDetails.charts.map((chart) => _buildChartCard(chart)).toList(),
      ],
    );
  }

  Widget _buildChartCard(details.ReportChart chart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chart.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildChart(chart),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(details.ReportChart chart) {
    switch (chart.type) {
      case 'pie':
        return _buildPieChart(chart);
      case 'bar':
        return _buildBarChart(chart);
      default:
        return _buildPlaceholderChart(chart);
    }
  }

  Widget _buildPieChart(details.ReportChart chart) {
    return PieChart(
      PieChartData(
        sections: chart.data.asMap().entries.map((entry) {
          final index = chart.data.indexOf(entry.value);
          final colors = [
            Colors.blue.shade600,
            Colors.green.shade600,
            Colors.orange.shade600,
            Colors.purple.shade600,
            Colors.red.shade600,
          ];
          
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value.value,
            title: '${entry.value.label}\n${entry.value.value.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            // badgeStyle: const TextStyle(
            //   fontSize: 14,
            //   fontWeight: FontWeight.bold,
            //   color: Colors.white,
            // ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        centerSpaceColor: Colors.white,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildBarChart(details.ReportChart chart) {
    // For bar charts, show different data based on report range
    final chartData = _getBarChartData(chart);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final style = TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                );
                
                final label = chartData[value.toInt()].label ?? '';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(label, style: style),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartData.asMap().entries.map((entry) {
          final index = chartData.indexOf(entry.value);
          final colors = [
            Colors.blue.shade600,
            Colors.green.shade600,
            Colors.orange.shade600,
            Colors.purple.shade600,
            Colors.red.shade600,
            Colors.teal.shade600,
            Colors.indigo.shade600,
          ];
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: colors[index % colors.length],
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<details.ChartData> _getBarChartData(details.ReportChart chart) {
    final range = widget.selectedRange ?? widget.reportItem.rangeKey;
    
    switch (range) {
      case 'daily':
        // For daily reports, show item-based data (top selling items)
        return [
          const details.ChartData(label: 'Burger', value: 1250.0),
          const details.ChartData(label: 'Pizza', value: 980.0),
          const details.ChartData(label: 'Pasta', value: 750.0),
          const details.ChartData(label: 'Salad', value: 420.0),
          const details.ChartData(label: 'Drinks', value: 680.0),
          const details.ChartData(label: 'Desserts', value: 320.0),
        ];
      case 'weekly':
        // For weekly reports, show daily data
        return [
          const details.ChartData(label: 'Mon', value: 2100.0),
          const details.ChartData(label: 'Tue', value: 2400.0),
          const details.ChartData(label: 'Wed', value: 2800.0),
          const details.ChartData(label: 'Thu', value: 2200.0),
          const details.ChartData(label: 'Fri', value: 3200.0),
          const details.ChartData(label: 'Sat', value: 2800.0),
          const details.ChartData(label: 'Sun', value: 1900.0),
        ];
      case 'monthly':
        // For monthly reports, show weekly data
        return [
          const details.ChartData(label: 'Week 1', value: 8500.0),
          const details.ChartData(label: 'Week 2', value: 9200.0),
          const details.ChartData(label: 'Week 3', value: 7800.0),
          const details.ChartData(label: 'Week 4', value: 10200.0),
          const details.ChartData(label: 'Week 5', value: 11500.0),
        ];
      case 'custom':
        // For custom date range, show date-based data
        return [
          const details.ChartData(label: '01/01', value: 2100.0),
          const details.ChartData(label: '02/01', value: 2400.0),
          const details.ChartData(label: '03/01', value: 2800.0),
          const details.ChartData(label: '04/01', value: 2200.0),
          const details.ChartData(label: '05/01', value: 3200.0),
          const details.ChartData(label: '06/01', value: 2800.0),
        ];
      default:
        // Default to item-based data
        return chart.data;
    }
  }

  Widget _buildPlaceholderChart(details.ReportChart chart) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Chart Visualization',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '(${chart.type} chart)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildMetadataRow('Report ID', reportDetails.id),
              _buildMetadataRow('Generated By', reportDetails.metadata?['generatedBy'] ?? 'System'),
              _buildMetadataRow('Format', reportDetails.metadata?['format'] ?? 'PDF'),
              _buildMetadataRow('File Size', reportDetails.metadata?['size'] ?? 'Unknown'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _downloadReport() {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
