import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../buttons/buttons.dart';

class AppDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancel;
  final bool isDestructive;
  final Widget? icon;

  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
    this.isDestructive = false,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    Widget? content,
    String? confirmText,
    String? cancelText,
    bool showCancel = true,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: title,
        message: message,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        showCancel: showCancel,
        isDestructive: isDestructive,
        icon: icon,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: AppSpacing.md),
            ],
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (message != null) ...[
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (content != null) ...[
              content!,
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                if (showCancel) ...[
                  Expanded(
                    child: SecondaryButton(
                      text: cancelText ?? 'Cancel',
                      onPressed: onCancel,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: PrimaryButton(
                    text: confirmText ?? 'Confirm',
                    onPressed: onConfirm,
                    fullWidth: true,
                    backgroundColor: isDestructive ? AppColors.error : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
