import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/app_config.dart';
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
        _buildFilters(context, controller),
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
                itemCount: controller.users.length,
                itemBuilder: (context, index) {
                  final user = controller.users[index];
                  return UserCard(
                    user: user,
                    onEdit: () => _showUserDialog(context, user: user),
                    onToggleActive: () => user.isActive
                        ? controller.deactivateUser(user.id)
                        : controller.activateUser(user.id),
                    onAssignRoles: () => _showAssignRolesDialog(context, user),
                    onResetPassword: () => _showResetPasswordDialog(context, user),
                  );
                },
              ),
            );
          }),
        ),
        _buildPagination(context, controller),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, UsersController controller) {
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
              padding: const EdgeInsets.all(AppConfig.padding),
              child: Align(
                alignment: Alignment.topCenter,
                child: UserTable(
                  users: controller.users,
                  onEdit: (user) => _showUserDialog(context, user: user),
                  onToggleActive: (user) => user.isActive
                      ? controller.deactivateUser(user.id)
                      : controller.activateUser(user.id),
                  onAssignRoles: (user) => _showAssignRolesDialog(context, user),
                  onResetPassword: (user) => _showResetPasswordDialog(context, user),
                ),
              ),
            );
          }),
        ),
        _buildPagination(context, controller),
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
                child: UserTable(
                  users: controller.users,
                  onEdit: (user) => _showUserDialog(context, user: user),
                  onToggleActive: (user) => user.isActive
                      ? controller.deactivateUser(user.id)
                      : controller.activateUser(user.id),
                  onAssignRoles: (user) => _showAssignRolesDialog(context, user),
                  onResetPassword: (user) => _showResetPasswordDialog(context, user),
                ),
              ),
            );
          }),
        ),
        _buildPagination(context, controller),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UsersController controller, {bool showMenuButton = false}) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
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
          const Icon(EvaIcons.people, size: 24),
          const SizedBox(width: 12),
          Text(
            'User Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showUserDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, UsersController controller) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(EvaIcons.funnelOutline, size: 18),
          const SizedBox(width: 8),
          const Text('Filter:'),
          const SizedBox(width: 12),
          Obx(() => FilterChip(
                label: const Text('All'),
                selected: controller.filterIsActive.value == null,
                onSelected: (_) => controller.toggleActiveFilter(null),
              )),
          const SizedBox(width: 8),
          Obx(() => FilterChip(
                label: const Text('Active'),
                selected: controller.filterIsActive.value == true,
                onSelected: (_) => controller.toggleActiveFilter(true),
              )),
          const SizedBox(width: 8),
          Obx(() => FilterChip(
                label: const Text('Inactive'),
                selected: controller.filterIsActive.value == false,
                onSelected: (_) => controller.toggleActiveFilter(false),
              )),
          const Spacer(),
          Obx(() => Text(
                '${controller.totalUsers.value} users',
                style: Theme.of(context).textTheme.bodySmall,
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
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${controller.currentPageNumber} of ${controller.totalPages}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: controller.hasPrevious
                      ? controller.loadPreviousPage
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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
