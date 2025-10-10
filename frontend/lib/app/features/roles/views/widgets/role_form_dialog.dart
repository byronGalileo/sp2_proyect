import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../models/role.dart';
import '../../../../models/permission.dart';
import '../../controllers/roles_controller.dart';

class RoleFormDialog extends StatefulWidget {
  final Role? role; // null for create, non-null for edit

  const RoleFormDialog({Key? key, this.role}) : super(key: key);

  @override
  State<RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _selectedPermissions = <int>{};
  bool _isActive = true;
  bool _isSystemRole = false;

  @override
  void initState() {
    super.initState();

    if (widget.role != null) {
      // Edit mode - populate fields
      _nameController.text = widget.role!.name;
      _displayNameController.text = widget.role!.displayName;
      _descriptionController.text = widget.role!.description ?? '';
      _isActive = widget.role!.isActive;
      _isSystemRole = widget.role!.isSystemRole;
      _selectedPermissions.addAll(
        widget.role!.permissions.map((p) => p.id),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one permission is selected
    if (_selectedPermissions.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select at least one permission',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final controller = Get.find<RolesController>();
    bool success;

    if (widget.role == null) {
      // Create new role
      success = await controller.createRole(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        permissionIds: _selectedPermissions.toList(),
        isActive: _isActive,
      );
    } else {
      // Update existing role
      success = await controller.updateRole(
        roleId: widget.role!.id,
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        permissionIds: _selectedPermissions.toList(),
        isActive: _isActive,
      );
    }

    if (success) {
      Get.back(); // Close dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RolesController>();
    final isEditMode = widget.role != null;
    final canEdit = !_isSystemRole || !isEditMode;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditMode ? 'Edit Role' : 'Create New Role',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (_isSystemRole && isEditMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'SYSTEM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System role warning
            if (_isSystemRole && isEditMode) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a system role. Editing is restricted to prevent breaking core functionality.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'e.g., admin, user, manager',
                          border: OutlineInputBorder(),
                        ),
                        enabled: canEdit,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Display Name
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name *',
                          hintText: 'e.g., Administrator, User, Manager',
                          border: OutlineInputBorder(),
                        ),
                        enabled: canEdit,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of this role',
                          border: OutlineInputBorder(),
                        ),
                        enabled: canEdit,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Active Status
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Enable or disable this role'),
                        value: _isActive,
                        onChanged: canEdit
                            ? (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              }
                            : null,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Permissions Section
                      Text(
                        'Permissions *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      Obx(() {
                        if (controller.isLoadingPermissions.value) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final permissions = controller.availablePermissions;

                        if (permissions.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No permissions available'),
                            ),
                          );
                        }

                        // Group permissions by resource
                        final groupedPermissions = <String, List<Permission>>{};
                        for (final permission in permissions) {
                          final resource = permission.resource ?? 'General';
                          if (!groupedPermissions.containsKey(resource)) {
                            groupedPermissions[resource] = [];
                          }
                          groupedPermissions[resource]!.add(permission);
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(
                              AppConfig.borderRadius,
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupedPermissions.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final resource =
                                  groupedPermissions.keys.elementAt(index);
                              final resourcePermissions =
                                  groupedPermissions[resource]!;

                              return ExpansionTile(
                                title: Text(
                                  resource,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                initiallyExpanded: true,
                                children: resourcePermissions.map((permission) {
                                  return CheckboxListTile(
                                    title: Text(permission.displayName),
                                    subtitle: permission.description != null
                                        ? Text(
                                            permission.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                        : null,
                                    value: _selectedPermissions
                                        .contains(permission.id),
                                    onChanged: canEdit
                                        ? (value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedPermissions
                                                    .add(permission.id);
                                              } else {
                                                _selectedPermissions
                                                    .remove(permission.id);
                                              }
                                            });
                                          }
                                        : null,
                                    dense: true,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  return ElevatedButton(
                    onPressed: controller.isLoading.value || !canEdit
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditMode ? 'Update' : 'Create'),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
