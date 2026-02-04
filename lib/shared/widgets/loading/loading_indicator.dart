import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

enum LoadingSize { small, medium, large }

class LoadingIndicator extends StatelessWidget {
  final LoadingSize size;
  final Color? color;
  final double? strokeWidth;

  const LoadingIndicator({
    super.key,
    this.size = LoadingSize.medium,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = _getDimension();
    final stroke = strokeWidth ?? _getStrokeWidth();

    return SizedBox(
      width: dimension,
      height: dimension,
      child: CircularProgressIndicator(
        strokeWidth: stroke,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }

  double _getDimension() {
    switch (size) {
      case LoadingSize.small:
        return 16;
      case LoadingSize.medium:
        return 24;
      case LoadingSize.large:
        return 40;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.small:
        return 2;
      case LoadingSize.medium:
        return 3;
      case LoadingSize.large:
        return 4;
    }
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? overlayColor;
  final Widget? loadingWidget;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.overlayColor,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: overlayColor ?? AppColors.overlay.withValues(alpha: 0.3),
              child: Center(
                child: loadingWidget ?? const LoadingIndicator(size: LoadingSize.large),
              ),
            ),
          ),
      ],
    );
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;

  const FullScreenLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicator(size: LoadingSize.large),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
