import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

enum IconButtonSize { small, medium, large }
enum IconButtonVariant { filled, outlined, ghost }

class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final IconButtonSize size;
  final IconButtonVariant variant;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final bool isDisabled;

  const IconButtonWidget({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = IconButtonSize.medium,
    this.variant = IconButtonVariant.ghost,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = _getIconSize();
    final buttonSize = _getButtonSize();
    final iconColor = isDisabled 
        ? AppColors.textHint 
        : (color ?? _getDefaultColor());

    Widget button = switch (variant) {
      IconButtonVariant.filled => _buildFilledButton(iconSize, buttonSize, iconColor),
      IconButtonVariant.outlined => _buildOutlinedButton(iconSize, buttonSize, iconColor),
      IconButtonVariant.ghost => _buildGhostButton(iconSize, buttonSize, iconColor),
    };

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  Widget _buildFilledButton(double iconSize, double buttonSize, Color iconColor) {
    return Material(
      color: isDisabled 
          ? AppColors.textHint.withValues(alpha: 0.3) 
          : (backgroundColor ?? AppColors.primary),
      borderRadius: AppSpacing.borderRadiusSm,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: AppSpacing.borderRadiusSm,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Icon(
            icon,
            size: iconSize,
            color: isDisabled ? AppColors.textHint : AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(double iconSize, double buttonSize, Color iconColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: AppSpacing.borderRadiusSm,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled ? AppColors.textHint : iconColor,
            ),
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(double iconSize, double buttonSize, Color iconColor) {
    return IconButton(
      onPressed: isDisabled ? null : onPressed,
      icon: Icon(icon, size: iconSize, color: iconColor),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: buttonSize,
        minHeight: buttonSize,
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case IconButtonSize.small:
        return 16;
      case IconButtonSize.medium:
        return 20;
      case IconButtonSize.large:
        return 24;
    }
  }

  double _getButtonSize() {
    switch (size) {
      case IconButtonSize.small:
        return 28;
      case IconButtonSize.medium:
        return 36;
      case IconButtonSize.large:
        return 44;
    }
  }

  Color _getDefaultColor() {
    switch (variant) {
      case IconButtonVariant.filled:
        return AppColors.textOnPrimary;
      case IconButtonVariant.outlined:
      case IconButtonVariant.ghost:
        return AppColors.textPrimary;
    }
  }
}
