import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/constants/app_text_styles.dart';

enum CustomLoaderSize { small, medium, large }

class CustomLoader extends StatelessWidget {
  final CustomLoaderSize size;
  final Color? color;
  final double? strokeWidth;
  final String? message;

  const CustomLoader({
    super.key,
    this.size = CustomLoaderSize.medium,
    this.color,
    this.strokeWidth,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = _getDimension();
    final stroke = strokeWidth ?? _getStrokeWidth();

    final indicator = SizedBox(
      width: dimension,
      height: dimension,
      child: CircularProgressIndicator(
        strokeWidth: stroke,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );

    if (message == null) return indicator;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: AppSpacing.sm),
        Text(
          message!,
          style: AppTextStyles.textSecondary14Regular,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  double _getDimension() {
    switch (size) {
      case CustomLoaderSize.small:
        return 16;
      case CustomLoaderSize.medium:
        return 24;
      case CustomLoaderSize.large:
        return 40;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case CustomLoaderSize.small:
        return 2;
      case CustomLoaderSize.medium:
        return 3;
      case CustomLoaderSize.large:
        return 4;
    }
  }
}
