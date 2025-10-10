import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../config/app_config.dart';
import '../../../../auth/controllers/auth_controller.dart';
import '../../../../../models/user.dart';
import '../../../../../shared_components/responsive_builder.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (authController) {
        final user = authController.user;

        if (user == null) {
          return const Center(
            child: Text('No user data available'),
          );
        }

        return ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return _buildMobileLayout(context, user);
          },
          tabletBuilder: (context, constraints) {
            return _buildTabletLayout(context, user);
          },
          desktopBuilder: (context, constraints) {
            return _buildDesktopLayout(context, user);
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.padding),
      child: Column(
        children: [
          _buildUserHeader(context, user),
          const SizedBox(height: 24),
          _buildProfileInfo(context, user),
          const SizedBox(height: 16),
          _buildAccountInfo(context, user),
          const SizedBox(height: 16),
          _buildPermissionsCard(context, user),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.padding * 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildUserHeader(context, user),
                const SizedBox(height: 24),
                _buildAccountInfo(context, user),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildProfileInfo(context, user),
                const SizedBox(height: 16),
                _buildPermissionsCard(context, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, User user) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.padding * 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildUserHeader(context, user),
                    const SizedBox(height: 24),
                    _buildAccountInfo(context, user),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildProfileInfo(context, user),
                    const SizedBox(height: 16),
                    _buildPermissionsCard(context, user),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor,
              child: user.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarText(context, user);
                        },
                      ),
                    )
                  : _buildAvatarText(context, user),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (!user.emailVerified)
                  Chip(
                    label: const Text('Email Not Verified'),
                    backgroundColor: Colors.orange[100],
                    avatar: const Icon(Icons.warning, size: 16, color: Colors.orange),
                  ),
                if (!user.isActive)
                  Chip(
                    label: const Text('Inactive'),
                    backgroundColor: Colors.red[100],
                    avatar: const Icon(Icons.block, size: 16, color: Colors.red),
                  )
                else
                  Chip(
                    label: const Text('Active'),
                    backgroundColor: Colors.green[100],
                    avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarText(BuildContext context, User user) {
    return Text(
      user.username.substring(0, 1).toUpperCase(),
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.person, 'Username', user.username),
            const Divider(),
            _buildInfoRow(Icons.email, 'Email', user.email),
            const Divider(),
            _buildInfoRow(
              Icons.phone,
              'Phone',
              user.phone ?? 'Not provided',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.person_outline,
              'First Name',
              user.firstName ?? 'Not provided',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.person_outline,
              'Last Name',
              user.lastName ?? 'Not provided',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Edit profile feature will be available soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo(BuildContext context, User user) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.calendar_today,
              'Member Since',
              dateFormat.format(user.createdAt),
            ),
            if (user.lastLoginAt != null) ...[
              const Divider(),
              _buildInfoRow(
                Icons.access_time,
                'Last Login',
                dateFormat.format(user.lastLoginAt!),
              ),
            ],
            const Divider(),
            _buildInfoRow(
              Icons.verified_user,
              'Account Status',
              user.isActive ? 'Active' : 'Inactive',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.email_outlined,
              'Email Verification',
              user.emailVerified ? 'Verified' : 'Not Verified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(BuildContext context, User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roles & Permissions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (user.roles.isNotEmpty) ...[
              Text(
                'Roles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.roles.map((role) {
                  return Chip(
                    label: Text(role),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                'No roles assigned',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (user.permissions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Permissions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              ...user.permissions.map((permission) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          permission,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else if (user.roles.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'No permissions assigned',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
