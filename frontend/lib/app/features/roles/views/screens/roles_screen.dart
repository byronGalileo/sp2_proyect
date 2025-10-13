import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_config.dart';
import '../../../../models/role.dart';
import '../../../../shared_components/responsive_builder.dart';
import '../../../../shared_components/base_screen_wrapper.dart';
import '../../controllers/roles_controller.dart';
import '../widgets/role_form_dialog.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseScreenWrapper(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoleDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New Role'),
      ),
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
        Padding(
          padding: const EdgeInsets.all(AppConfig.padding),
          child: _buildHeader(context, showMenuButton: true),
        ),
        _buildSearchBar(context),
        Expanded(child: _buildRolesList(context, isMobile: true)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.padding),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildSearchBar(context),
            const SizedBox(height: 16),
            _buildRolesTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.padding * 2),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildSearchBar(context),
            const SizedBox(height: 16),
            _buildRolesTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool showMenuButton = false}) {
    return Row(
      children: [
        if (showMenuButton) ...[
          const DrawerMenuButton(),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            'Roles Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            final controller = Get.find<RolesController>();
            controller.fetchRoles();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final controller = Get.find<RolesController>();

    return Padding(
      padding: const EdgeInsets.all(AppConfig.padding),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search roles...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) => controller.searchRoles(value),
      ),
    );
  }

  Widget _buildRolesList(BuildContext context, {required bool isMobile}) {
    final controller = Get.find<RolesController>();

    return Obx(() {
      if (controller.isLoading.value && controller.roles.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredRoles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No roles found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchRoles(),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppConfig.padding),
          itemCount: controller.filteredRoles.length,
          itemBuilder: (context, index) {
            final role = controller.filteredRoles[index];
            return _buildRoleCard(context, role);
          },
        ),
      );
    });
  }

  Widget _buildRoleCard(BuildContext context, Role role) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final createdDate = role.createdAt != null
        ? dateFormat.format(role.createdAt!)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: InkWell(
        onTap: () => _showRoleDialog(context, role),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                role.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (role.isSystemRole)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.lock,
                                        size: 12, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text(
                                      'SYSTEM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      role.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: role.isActive
                        ? Colors.green[100]
                        : Colors.grey[300],
                    avatar: Icon(
                      role.isActive ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: role.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (role.description != null && role.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  role.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.security,
                    label: '${role.permissions.length} permissions',
                    color: Colors.blue,
                  ),
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: createdDate,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTable(BuildContext context) {
    final controller = Get.find<RolesController>();

    return Obx(() {
      if (controller.isLoading.value && controller.roles.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredRoles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No roles found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Display Name')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Permissions')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Created')),
              DataColumn(label: Text('Actions')),
            ],
            rows: controller.filteredRoles.map((role) {
              final dateFormat = DateFormat('MMM dd, yyyy');
              final createdDate = role.createdAt != null
                  ? dateFormat.format(role.createdAt!)
                  : 'N/A';
              return DataRow(
                cells: [
                  DataCell(Text(role.name)),
                  DataCell(Text(role.displayName)),
                  DataCell(
                    Chip(
                      label: Text(
                        role.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: role.isActive
                          ? Colors.green[100]
                          : Colors.grey[300],
                      avatar: Icon(
                        role.isActive ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: role.isActive ? Colors.green : Colors.grey,
                      ),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${role.permissions.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    role.isSystemRole
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.lock, size: 12, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  'SYSTEM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Text('Custom'),
                  ),
                  DataCell(Text(createdDate)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showRoleDialog(context, role),
                      tooltip: 'Edit',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  void _showRoleDialog(BuildContext context, Role? role) {
    showDialog(
      context: context,
      builder: (context) => RoleFormDialog(role: role),
    );
  }
}
