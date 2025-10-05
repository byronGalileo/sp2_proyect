// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';

class AppRoutes {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthCheckComplete = authProvider.isAuthCheckComplete;
        final isAuthenticated = authProvider.isAuthenticated;
        final isGoingToLogin = state.fullPath == '/login';
        final isGoingToSplash = state.fullPath == '/splash';

        if (!isAuthCheckComplete) {
          return isGoingToSplash ? null : '/splash';
        }

        if (isAuthenticated) {
          if (isGoingToLogin || isGoingToSplash) {
            return '/home';
          }
        } else {
          if (!isGoingToLogin && state.fullPath != '/register') {
            return '/login';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
      errorBuilder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Page not found'),
        ),
      ),
    );
  }
}