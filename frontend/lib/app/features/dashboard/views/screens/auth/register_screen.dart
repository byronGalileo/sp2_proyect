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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Get.find<AuthController>();

    final success = await authController.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim().isEmpty
          ? null
          : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (success) {
      // Reset failed attempts on successful registration
      _failedAttempts = 0;
      // Navigate to home
      Get.offAllNamed(Routes.home);
    } else {
      // Increment failed attempts
      _failedAttempts++;

      // Clear password fields after 3 failed attempts
      if (_failedAttempts >= 3) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        _failedAttempts = 0; // Reset counter
      }

      final errorMsg = authController.errorMessage ?? 'Registration failed';
      Get.snackbar(
        'Registration Failed',
        errorMsg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
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
          constraints: const BoxConstraints(maxWidth: 600),
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
          constraints: const BoxConstraints(maxWidth: 900),
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
            title: 'Create Account',
            subtitle: 'Sign up to get started',
          ),
          const SizedBox(height: 32),

          // First Name and Last Name Row
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Username
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            prefixIcon: Icons.alternate_email,
            validator: Validators.username,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Phone (Optional)
          CustomTextField(
            controller: _phoneController,
            label: 'Phone (Optional)',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Password
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: Validators.password,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Confirm Password
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) => Validators.confirmPassword(
              value,
              _passwordController.text,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
          ),

          const SizedBox(height: 32),

          // Register Button
          CustomButton(
            text: 'Create Account',
            onPressed: _register,
            isLoading: authController.isLoading,
          ),

          const SizedBox(height: 24),

          // Sign In Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? '),
              TextButton(
                onPressed: () => Get.toNamed(Routes.login),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
