import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/constants.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: isCircle ? null : (borderRadius ?? AppSpacing.borderRadiusSm),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    required this.width,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: AppSpacing.borderRadiusXs,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width ?? double.infinity,
      height: height ?? 100,
      borderRadius: AppSpacing.borderRadiusMd,
    );
  }
}

class TableSkeleton extends StatelessWidget {
  final int count;

  const TableSkeleton({super.key, this.count = 12});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return const SkeletonLoader(
          borderRadius: AppSpacing.borderRadiusSm,
        );
      },
    );
  }
}

class MenuItemSkeleton extends StatelessWidget {
  const MenuItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppSpacing.borderRadiusXs,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppSpacing.borderRadiusXs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
