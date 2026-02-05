import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import 'router/app_router.dart';

class RestroPosApp extends ConsumerStatefulWidget {
  const RestroPosApp({super.key});

  @override
  ConsumerState<RestroPosApp> createState() => _RestroPosAppState();
}

class _RestroPosAppState extends ConsumerState<RestroPosApp> {
  @override
  void initState() {
    super.initState();
    // Start session restoration asynchronously without blocking
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Small delay to ensure the widget is fully built
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      // Restore session asynchronously
      await ref.read(authProvider.notifier).restoreSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RestroPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
