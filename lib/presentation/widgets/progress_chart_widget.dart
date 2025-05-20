// File: lib/presentation/widgets/progress_chart_widget.dart

import 'package:flutter/material.dart';
import '../../core/utils/app_colors.dart';

class ProgressChartWidget extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double completionPercentage;

  const ProgressChartWidget({
    Key? key,
    required this.completedCount,
    required this.totalCount,
    required this.completionPercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For simpler MVP, we're using a linear progress indicator
    // In a future version, this could be replaced with a more advanced chart
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: AppColors.progressBarBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 8),
        // Percentage text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${completionPercentage.toStringAsFixed(1)}% Complete',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$completedCount of $totalCount lessons',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}