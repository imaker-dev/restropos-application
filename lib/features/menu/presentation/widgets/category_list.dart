import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../data/models/menu_models.dart';
import '../providers/menu_provider.dart';

class CategoryList extends ConsumerWidget {
  final Axis direction;

  const CategoryList({super.key, this.direction = Axis.vertical});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuProvider);
    final categories = menuState.categories;
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    // Show loading indicator
    if (menuState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Show error if any
    if (menuState.error != null) {
      return Center(
        child: Text(
          menuState.error!,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show message if no categories
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    if (direction == Axis.horizontal) {
      return SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          itemCount: categories.length + 1, // +1 for "All"
          itemBuilder: (context, index) {
            if (index == 0) {
              // "All" chip
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _AllCategoryChip(
                  isSelected: selectedCategoryId == null,
                  onTap: () =>
                      ref.read(menuProvider.notifier).selectCategory(null),
                ),
              );
            }
            final category = categories[index - 1];
            final isSelected = category.id == selectedCategoryId;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _CategoryChip(
                category: category,
                isSelected: isSelected,
                onTap: () =>
                    ref.read(menuProvider.notifier).selectCategory(category.id),
              ),
            );
          },
        ),
      );
    }

    return Container(
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: categories.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" tile
            return _AllCategoryTile(
              isSelected: selectedCategoryId == null,
              itemCount: menuState.items.length,
              onTap: () => ref.read(menuProvider.notifier).selectCategory(null),
            );
          }
          final category = categories[index - 1];
          final isSelected = category.id == selectedCategoryId;
          return _CategoryTile(
            category: category,
            isSelected: isSelected,
            onTap: () =>
                ref.read(menuProvider.notifier).selectCategory(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ApiCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: AppSpacing.borderRadiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            category.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AllCategoryChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AllCategoryChip({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: AppSpacing.borderRadiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            'All',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AllCategoryTile extends StatelessWidget {
  final bool isSelected;
  final int itemCount;
  final VoidCallback onTap;

  const _AllCategoryTile({
    required this.isSelected,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const Expanded(
                child: Text(
                  'All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ApiCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
