import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/auth_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _passcode = '';
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_passcode.length < 6) {
      setState(() {
        _passcode += digit;
      });
      ref.read(authProvider.notifier).clearError();
      
      // Auto-submit when 6 digits entered
      if (_passcode.length == 6) {
        _submitPasscode();
      }
    }
  }

  void _onBackspace() {
    if (_passcode.isNotEmpty) {
      setState(() {
        _passcode = _passcode.substring(0, _passcode.length - 1);
      });
      ref.read(authProvider.notifier).clearError();
    }
  }

  Future<void> _submitPasscode() async {
    if (_passcode.length == 4) {
      final success = await ref.read(authProvider.notifier).loginWithPasscode(_passcode);
      if (!success) {
        setState(() {
          _passcode = '';
        });
      }
    }
  }

  Future<void> _submitCredentials() async {
    if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      await ref.read(authProvider.notifier).loginWithCredentials(
        _usernameController.text,
        _passwordController.text,
      );
    }
  }

  void _onLoginModeChanged(LoginMode mode) {
    ref.read(authProvider.notifier).setLoginMode(mode);
    setState(() {
      _passcode = '';
    });
    _usernameController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(authState),
        tablet: _buildTabletLayout(authState),
        desktop: _buildDesktopLayout(authState),
      ),
    );
  }

  Widget _buildDesktopLayout(AuthState authState) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 2,
          child: Container(
            color: AppColors.surface,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPOSIllustration(),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'RestroPOS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Restaurant Point of Sale System',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Center - Login Form
        Expanded(
          flex: 3,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildLoginForm(authState),
            ),
          ),
        ),
        // Right side - Login Mode Selector
        Container(
          width: 100,
          color: AppColors.surface,
          child: Center(
            child: LoginModeSelector(
              currentMode: authState.loginMode,
              onModeChanged: _onLoginModeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(AuthState authState) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildLoginForm(authState),
            ),
          ),
        ),
        Container(
          width: 100,
          color: AppColors.surface,
          child: Center(
            child: LoginModeSelector(
              currentMode: authState.loginMode,
              onModeChanged: _onLoginModeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AuthState authState) {
    return SafeArea(
      child: Column(
        children: [
          // Login mode tabs at top
          Container(
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMobileTab(
                  'Login',
                  Icons.person_outline,
                  LoginMode.credentials,
                  authState.loginMode,
                ),
                _buildMobileTab(
                  'Passcode',
                  Icons.dialpad,
                  LoginMode.passcode,
                  authState.loginMode,
                ),
                // _buildMobileTab(
                //   'Card',
                //   Icons.credit_card,
                //   LoginMode.cardSwipe,
                //   authState.loginMode,
                // ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingMd,
                child: _buildLoginForm(authState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTab(String label, IconData icon, LoginMode mode, LoginMode currentMode) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: () => _onLoginModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthState authState) {
    switch (authState.loginMode) {
      case LoginMode.passcode:
        return _buildPasscodeForm(authState);
      case LoginMode.credentials:
        return _buildCredentialsForm(authState);
      case LoginMode.pin:
        return _buildPinForm(authState);
      // case LoginMode.cardSwipe:
      //   return _buildCardSwipeForm(authState);
    }
  }

  Widget _buildPasscodeForm(AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter the Passcode to access this Billing Station',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        PasscodeDots(
          filledCount: _passcode.length,
          hasError: authState.hasError,
        ),
        if (authState.hasError) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            authState.errorMessage ?? 'Invalid passcode',
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        PasscodeKeypad(
          onDigitPressed: _onDigitPressed,
          onBackspace: _onBackspace,
          onSubmit: _submitPasscode,
          isLoading: authState.isLoading,
        ),
        if (authState.isLoading) ...[
          const SizedBox(height: AppSpacing.lg),
          const LoadingIndicator(),
        ],
      ],
    );
  }

  Widget _buildCredentialsForm(AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Login to RestroPOS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextInput(
          label: 'Username',
          hint: 'Enter your username',
          controller: _usernameController,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: AppSpacing.md),
        TextInput(
          label: 'Password',
          hint: 'Enter your password',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
          onSubmitted: (_) => _submitCredentials(),
        ),
        if (authState.hasError) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            authState.errorMessage ?? 'Invalid credentials',
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          text: 'Login',
          onPressed: _submitCredentials,
          isLoading: authState.isLoading,
          fullWidth: true,
          size: ButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildPinForm(AuthState authState) {
    return _buildPasscodeForm(authState);
  }

  Widget _buildCardSwipeForm(AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.credit_card,
          size: 80,
          color: AppColors.textHint,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Swipe your card to login',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Card swipe functionality coming soon',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPOSIllustration() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Center(
        child: Icon(
          Icons.point_of_sale,
          size: 100,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
