import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ReportHeader extends StatelessWidget {
  const ReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text(
            "Sales Reports",
            style: AppTextStyles.primary16Bold,
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
          )
        ],
      ),
    );
  }
}
