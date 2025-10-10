import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../config/app_config.dart';
import '../../../../../config/routes/app_pages.dart';
import '../../../../auth/controllers/auth_controller.dart';
import '../../widgets/common/loading_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authController = Get.find<AuthController>();

    // Wait for auth check to complete
    await authController.checkAuthStatus();

    // Navigate based on auth status
    await Future.delayed(const Duration(seconds: 1)); // Brief delay for UX

    if (authController.isAuthenticated) {
      Get.offAllNamed(Routes.home);
    } else {
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storage,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              AppConfig.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'v${AppConfig.appVersion}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const LoadingWidget(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
