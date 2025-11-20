import 'package:flutter/material.dart';
import '../../../../../shared_components/responsive_builder.dart';
import '../../../../../shared_components/base_screen_wrapper.dart';
import '../../../../../config/app_config.dart';
import '../../../../../config/themes/app_theme.dart';
import 'profile_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenWrapper(
      child: ResponsiveBuilder(
        mobileBuilder: (context, constraints) {
          return _buildMobileLayout(context);
        },
        tabletBuilder: (context, constraints) {
          return _buildTabletLayout(context);
        },
        desktopBuilder: (context, constraints) {
          return _buildDesktopLayout(context);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, showMenuButton: true),
        const Expanded(child: ProfilePage()),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const Expanded(child: ProfilePage()),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context),
          const ProfilePage(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool showMenuButton = false}) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            const DrawerMenuButton(),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              'User Profile', // Changed title to be more specific
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Add a refresh button like in HostsScreen
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: () {
              // You might want to add a controller to ProfileScreen
              // to handle refresh logic, similar to HostsScreen.
              // For now, it's just a placeholder.
              // Get.find<ProfileController>().refreshProfileData();
              print('Refresh Profile Data');
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}
