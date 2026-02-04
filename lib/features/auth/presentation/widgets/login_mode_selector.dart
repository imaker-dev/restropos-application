import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/auth_state.dart';

class LoginModeSelector extends StatelessWidget {
  final LoginMode currentMode;
  final ValueChanged<LoginMode> onModeChanged;

  const LoginModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusSm,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LoginModeItem(
            icon: Icons.person_outline,
            label: 'Login',
            mode: LoginMode.credentials,
            isSelected: currentMode == LoginMode.credentials,
            onTap: () => onModeChanged(LoginMode.credentials),
          ),
          const Divider(height: 1),
          _LoginModeItem(
            icon: Icons.dialpad,
            label: 'Passcode',
            mode: LoginMode.passcode,
            isSelected: currentMode == LoginMode.passcode,
            onTap: () => onModeChanged(LoginMode.passcode),
          ),
          const Divider(height: 1),
          _LoginModeItem(
            icon: Icons.credit_card,
            label: 'Swipe Card',
            mode: LoginMode.cardSwipe,
            isSelected: currentMode == LoginMode.cardSwipe,
            onTap: () => onModeChanged(LoginMode.cardSwipe),
          ),
        ],
      ),
    );
  }
}

class _LoginModeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final LoginMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoginModeItem({
    required this.icon,
    required this.label,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
