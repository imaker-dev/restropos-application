import 'package:flutter/material.dart';

import '../providers/order_history_provider.dart';

class OrderHistoryFilters extends StatelessWidget {
  final OrderHistoryState state;
  final Function(String?) onStatusSelected;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final Function() onTodaySelected;
  final Function() onThisWeekSelected;
  final Function() onThisMonthSelected;
  final Function() onClearFilters;

  const OrderHistoryFilters({
    super.key,
    required this.state,
    required this.onStatusSelected,
    required this.onDateRangeSelected,
    required this.onTodaySelected,
    required this.onThisWeekSelected,
    required this.onThisMonthSelected,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          
          // Quick Date Filters
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTodaySelected,
                  child: const Text('Today'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onThisWeekSelected,
                  child: const Text('This Week'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onThisMonthSelected,
                  child: const Text('This Month'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status Filter
          const Text(
            'Filter by Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          
          // Status Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.selectedStatus == null,
                onSelected: (value) => onStatusSelected(null),
                backgroundColor: state.selectedStatus == null ? const Color(0xFF2D3748) : null,
              ),
              FilterChip(
                label: const Text('Completed'),
                selected: state.selectedStatus == 'completed',
                onSelected: (value) => onStatusSelected('completed'),
                backgroundColor: state.selectedStatus == 'completed' ? Colors.green : null,
              ),
              FilterChip(
                label: const Text('Cancelled'),
                selected: state.selectedStatus == 'cancelled',
                onSelected: (value) => onStatusSelected('cancelled'),
                backgroundColor: state.selectedStatus == 'cancelled' ? Colors.red : null,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date Range Filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onDateRangeSelected(null, null),
                  icon: const Icon(Icons.date_range),
                  label: Text(state.fromDate != null && state.toDate != null
                      ? '${_formatDate(state.fromDate!)} - ${_formatDate(state.toDate!)}'
                      : 'Select Date Range'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
