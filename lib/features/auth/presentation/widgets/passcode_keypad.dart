import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/constants.dart';

class PasscodeKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool isLoading;

  const PasscodeKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: AppSpacing.sm),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: AppSpacing.sm),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: AppSpacing.sm),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _KeypadButton(
            label: digit,
            onPressed: isLoading ? null : () => onDigitPressed(digit),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _KeypadButton(
            icon: Icons.backspace_outlined,
            iconColor: AppColors.error,
            onPressed: isLoading ? null : onBackspace,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _KeypadButton(
            label: '0',
            onPressed: isLoading ? null : () => onDigitPressed('0'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _KeypadButton(
            icon: Icons.keyboard_return,
            iconColor: AppColors.primary,
            onPressed: isLoading ? null : onSubmit,
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onPressed;

  const _KeypadButton({
    this.label,
    this.icon,
    this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 24,
                    color: iconColor ?? AppColors.textPrimary,
                  )
                : Text(
                    label ?? '',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
