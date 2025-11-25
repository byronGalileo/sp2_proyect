import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/widgets/loading_widget.dart';
import '../../../../models/user.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../controllers/users_controller.dart';
import '../widgets/user_card.dart';
import '../widgets/user_form_dialog.dart';
import '../widgets/user_table.dart';
import '../widgets/assign_roles_dialog.dart';
import '../widgets/reset_password_dialog.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();

    return BaseScreenWrapper(
      showMobileHeader: false,
      floatingActionButton: MediaQuery.of(context).size.width < 900
          ? FloatingActionButton.extended(
              onPressed: () => _showUserDialog(context),
              icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
              label: const Text('Add User'),
            )
          : null,
      child: ResponsiveBuilder(
        mobileBuilder: (context, constraints) {
          return _buildMobileLayout(context, controller);
        },
        tabletBuilder: (context, constraints) {
          return _buildTabletLayout(context, controller);
        },
        desktopBuilder: (context, constraints) {
          return _buildDesktopLayout(context, controller);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, UsersController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildFilters(context, controller, isMobile: true),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.users.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.users.isEmpty) {
              return const Center(child: Text('No users found'));
            }

            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConfig.padding),
                itemCount: controller.users.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.users.length) {
                    return _buildPagination(context, controller);
                  }
                  final user = controller.users[index];
                  return UserCard(
                    user: user,
                    onEdit: () => _showUserDialog(context, user: user),
                    onToggleActive: () => user.isActive
                        ? controller.deactivateUser(user.id)
                        : controller.activateUser(user.id),
                    onAssignRoles: () => _showAssignRolesDialog(context, user),
                    onResetPassword: () =>
                        _showResetPasswordDialog(context, user),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, UsersController controller) {
    return Column(
      children: [
        _buildHeader(context, controller, showMenuButton: true),
        _buildFilters(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.users.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.users.isEmpty) {
              return const Center(child: Text('No users found'));
            }

            return Padding(
              padding: const EdgeInsets.all(AppConfig.padding),
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: UserTable(
                    users: controller.users,
                    onEdit: (user) => _showUserDialog(context, user: user),
                    onToggleActive: (user) => user.isActive
                        ? controller.deactivateUser(user.id)
                        : controller.activateUser(user.id),
                    onAssignRoles: (user) => _showAssignRolesDialog(context, user),
                    onResetPassword: (user) =>
                        _showResetPasswordDialog(context, user),
                    footer: _buildPagination(context, controller),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, UsersController controller) {
    return Column(
      children: [
        _buildHeader(context, controller),
        _buildFilters(context, controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.users.isEmpty) {
              return const Center(child: LoadingWidget());
            }

            if (controller.users.isEmpty) {
              return const Center(child: Text('No users found'));
            }

            return Padding(
              padding: const EdgeInsets.all(AppConfig.padding * 2),
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: UserTable(
                    users: controller.users,
                    onEdit: (user) => _showUserDialog(context, user: user),
                    onToggleActive: (user) => user.isActive
                        ? controller.deactivateUser(user.id)
                        : controller.activateUser(user.id),
                    onAssignRoles: (user) => _showAssignRolesDialog(context, user),
                    onResetPassword: (user) =>
                        _showResetPasswordDialog(context, user),
                    footer: _buildPagination(context, controller),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UsersController controller, {bool showMenuButton = false}) {
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
            const DrawerMenuButton(), // Assuming this is already themed white
            const SizedBox(width: 8),
          ],
          const Icon(EvaIcons.people, size: 24, color: AppColors.accentOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'User Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Obx(() => controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppColors.textOnPrimary)),
            onPressed: controller.refresh,
            tooltip: 'Refresh',
          ),
          if (MediaQuery.of(context).size.width >= 900) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(context),
              icon: const Icon(Icons.add,
                  size: 18, color: AppColors.textOnPrimary),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBase,
                foregroundColor: AppColors.textOnPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, UsersController controller,
      {bool isMobile = false}) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.5),
      ),
      child: Row(
        children: [
          const Icon(EvaIcons.funnelOutline, size: 18, color: AppColors.textLight),
          const SizedBox(width: 8),
          const Text('Filter:', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(width: 12),
          Obx(() => FilterChip(
                label: const Text('All'),
                selected: controller.filterIsActive.value == null,
                onSelected: (_) => controller.toggleActiveFilter(null),
                selectedColor: AppColors.primaryBase,
                backgroundColor: AppColors.border,
                labelStyle: TextStyle(
                    color: controller.filterIsActive.value == null
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary),
              )),
          const SizedBox(width: 8),
          Obx(() => FilterChip(
                label: const Text('Active'),
                selected: controller.filterIsActive.value == true,
                onSelected: (_) => controller.toggleActiveFilter(true),
                selectedColor: AppColors.success,
                backgroundColor: AppColors.border,
                labelStyle: TextStyle(
                    color: controller.filterIsActive.value == true
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary),
              )),
          const SizedBox(width: 8),
          Obx(() => FilterChip(
                label: const Text('Inactive'),
                selected: controller.filterIsActive.value == false,
                onSelected: (_) => controller.toggleActiveFilter(false),
                selectedColor: AppColors.error,
                backgroundColor: AppColors.border,
                labelStyle: TextStyle(
                    color: controller.filterIsActive.value == false
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary),
              )),
          if (!isMobile) const Spacer(),
          if (isMobile) const SizedBox(width: 16),
          Obx(() => Text(
                '${controller.totalUsers.value} users',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
              )),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, UsersController controller) {
    return Obx(() {
      if (controller.users.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(AppConfig.padding),
        decoration: BoxDecoration(
          color: Colors.transparent, // Remove background color as it's now in card
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${controller.currentPageNumber} of ${controller.totalPages}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textLight),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textLight),
                  onPressed: controller.hasPrevious
                      ? controller.loadPreviousPage
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textLight),
                  onPressed:
                      controller.hasMore ? controller.loadNextPage : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showUserDialog(BuildContext context, {User? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  void _showAssignRolesDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AssignRolesDialog(user: user),
    );
  }

  void _showResetPasswordDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => ResetPasswordDialog(user: user),
    );
  }
}
