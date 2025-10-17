import 'package:daily_task/app/utils/helpers/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../config/app_config.dart';
import '../../../../../config/routes/app_pages.dart';
import '../../../../../shared_components/responsive_builder.dart';
import '../../../../../utils/validators.dart';
import '../../../../auth/controllers/auth_controller.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Get.find<AuthController>();

    final success = await authController.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      // Reset failed attempts on successful login
      _failedAttempts = 0;
      // Navigate to home
      Get.offAllNamed(Routes.home);
    } else {
      // Increment failed attempts
      _failedAttempts++;

      // Clear password after 3 failed attempts
      if (_failedAttempts >= 3) {
        _passwordController.clear();
        _failedAttempts = 0; // Reset counter
      }

      final errorMsg = authController.errorMessage ?? 'Login failed';
      SnackbarHelper.showSuccess(message: errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GetX<AuthController>(
          builder: (authController) {
            if (authController.isLoading) {
              return const Center(child: LoadingWidget());
            }

            return ResponsiveBuilder(
              mobileBuilder: (context, constraints) {
                return _buildMobileLayout(authController);
              },
              tabletBuilder: (context, constraints) {
                return _buildTabletLayout(authController);
              },
              desktopBuilder: (context, constraints) {
                return _buildDesktopLayout(authController);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AuthController authController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.padding),
      child: _buildForm(authController),
    );
  }

  Widget _buildTabletLayout(AuthController authController) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.padding * 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConfig.padding * 2),
              child: _buildForm(authController),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AuthController authController) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.padding * 3),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius * 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConfig.padding * 3),
              child: _buildForm(authController),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AuthController authController) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthHeader(
            title: 'Welcome Back',
            subtitle: 'Sign in to your account',
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _usernameController,
            label: 'Username or Email',
            prefixIcon: Icons.person_outline,
            validator: (value) => Validators.required(value, 'Username'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) => Validators.required(value, 'Password'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
                SnackbarHelper.showWarning(message: 'Forgot password feature coming soon');
              },
              child: const Text('Forgot Password?'),
            ),
          ),

          const SizedBox(height: 24),
          CustomButton(
            text: 'Sign In',
            onPressed: _login,
            isLoading: authController.isLoading,
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              TextButton(
                onPressed: () => Get.toNamed(Routes.register),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
