import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import 'primary_button.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.size = ButtonSize.medium,
    this.icon,
    this.fullWidth = false,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonPadding = _getPadding();
    final fontSize = _getFontSize();
    final color = borderColor ?? AppColors.primary;

    Widget child = isLoading
        ? SizedBox(
            width: fontSize + 4,
            height: fontSize + 4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 2),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final button = OutlinedButton(
      onPressed: isDisabled || isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? color,
        side: BorderSide(
          color: isDisabled ? AppColors.textHint : color,
        ),
        padding: buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
      ),
      child: child,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }
}
