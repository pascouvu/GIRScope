import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateFilterOption { last3Days, last7Days, last30Days, last60Days, last90Days, customRange }

class DateFilterDropdown extends StatelessWidget {
  final DateFilterOption selectedFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Function(DateFilterOption) onFilterChanged;
  final VoidCallback onCustomRangeSelected;

  const DateFilterDropdown({
    super.key,
    required this.selectedFilter,
    this.customStartDate,
    this.customEndDate,
    required this.onFilterChanged,
    required this.onCustomRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateFilterOption>(
          value: selectedFilter,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          onChanged: (DateFilterOption? newValue) {
            if (newValue != null) {
              if (newValue == DateFilterOption.customRange) {
                onCustomRangeSelected();
              } else {
                onFilterChanged(newValue);
              }
            }
          },
          items: [
            const DropdownMenuItem(
              value: DateFilterOption.last3Days,
              child: Text('Last 3 Days'),
            ),
            const DropdownMenuItem(
              value: DateFilterOption.last7Days,
              child: Text('Last 7 Days'),
            ),
            const DropdownMenuItem(
              value: DateFilterOption.last30Days,
              child: Text('Last 30 Days'),
            ),
            const DropdownMenuItem(
              value: DateFilterOption.last60Days,
              child: Text('Last 60 Days'),
            ),
            const DropdownMenuItem(
              value: DateFilterOption.last90Days,
              child: Text('Last 90 Days'),
            ),
            DropdownMenuItem(
              value: DateFilterOption.customRange,
              child: Text(_getFilterOptionLabel(DateFilterOption.customRange)),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterOptionLabel(DateFilterOption option) {
    switch (option) {
      case DateFilterOption.last3Days:
        return 'Last 3 Days';
      case DateFilterOption.last7Days:
        return 'Last 7 Days';
      case DateFilterOption.last30Days:
        return 'Last 30 Days';
      case DateFilterOption.last60Days:
        return 'Last 60 Days';
      case DateFilterOption.last90Days:
        return 'Last 90 Days';
      case DateFilterOption.customRange:
        if (option == selectedFilter && customStartDate != null && customEndDate != null) {
          return 'Custom (${DateFormat('dd/MM').format(customStartDate!)} - ${DateFormat('dd/MM').format(customEndDate!)})';
        }
        return 'Custom Range';
    }
  }
}