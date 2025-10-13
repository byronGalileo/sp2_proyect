import 'package:flutter/material.dart';
import '../../../../../shared_components/responsive_builder.dart';
import '../../../../../shared_components/base_screen_wrapper.dart';
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (showMenuButton) ...[
            const DrawerMenuButton(),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
