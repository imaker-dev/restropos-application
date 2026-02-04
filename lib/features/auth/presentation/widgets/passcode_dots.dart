import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class PasscodeDots extends StatelessWidget {
  final int length;
  final int filledCount;
  final bool hasError;

  const PasscodeDots({
    super.key,
    this.length = 4,
    required this.filledCount,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filledCount;
        return AnimatedContainer(
          duration: AppConstants.shortAnimation,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (hasError ? AppColors.error : AppColors.primary)
                : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : (isFilled ? AppColors.primary : AppColors.border),
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
