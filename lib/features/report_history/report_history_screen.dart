import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:restro/features/report_history/repository/widgets/report_filter_bar.dart';
import 'package:restro/features/report_history/repository/widgets/report_header.dart';
import 'package:restro/features/report_history/repository/widgets/report_list.dart';
import 'package:restro/features/report_history/repository/widgets/report_summary_card.dart';

import '../../core/constants/app_colors.dart';

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Report History"),
        elevation: 0,
      ),
      body: Column(
        children: const [
          ReportHeader(),
          ReportFilterBar(),
          ReportSummaryCard(),
          Expanded(child: ReportList()),
        ],
      ),
    );
  }
}
