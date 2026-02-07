import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restro/features/profile/presentation/profile_screen.dart';
import '../../features/auth/auth.dart';
import '../../features/orders/presentation/screens/screens.dart';
import '../screens/captain_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    debugLogDiagnostics: false,

    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isRestoring = authState.isSessionRestoring;

      final location = state.matchedLocation;
      final isLogin = location == '/login';

      if (isRestoring) {
        return null;
      }

      if (!isAuthenticated && !isLogin) {
        return '/login';
      }

      if (isAuthenticated && isLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const CaptainHomeScreen(),
        routes: [
          GoRoute(
            path: 'table/:tableId',
            name: 'order',
            builder: (context, state) {
              final tableId = state.pathParameters['tableId']!;
              return OrderScreen(tableId: tableId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
