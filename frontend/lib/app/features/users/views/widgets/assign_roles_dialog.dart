import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../models/user.dart';
import '../../../dashboard/views/widgets/common/custom_button.dart';
import '../../controllers/users_controller.dart';

class AssignRolesDialog extends StatefulWidget {
  final User user;

  const AssignRolesDialog({super.key, required this.user});

  @override
  State<AssignRolesDialog> createState() => _AssignRolesDialogState();
}

class _AssignRolesDialogState extends State<AssignRolesDialog> {
  final Set<int> _selectedRoleIds = {};

  @override
  void initState() {
    super.initState();
    final controller = Get.find<UsersController>();

    // Pre-select roles that the user already has
    for (final role in controller.availableRoles) {
      if (widget.user.roles.contains(role.name)) {
        _selectedRoleIds.add(role.id);
      }
    }
  }

  Future<void> _submit() async {
    final controller = Get.find<UsersController>();

    final success = await controller.assignRoles(
      userId: widget.user.id,
      roleIds: _selectedRoleIds.toList(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: constraints.maxHeight * 0.8,
            ),
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.padding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Assign Roles',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'User: ${widget.user.fullName} (@${widget.user.username})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              Flexible(
                child: GetX<UsersController>(
                  builder: (controller) {
                    if (controller.availableRoles.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text('No roles available'),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: controller.availableRoles.map((role) {
                          return CheckboxListTile(
                            title: Text(role.displayName),
                            subtitle: role.description != null
                                ? Text(role.description!)
                                : null,
                            value: _selectedRoleIds.contains(role.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedRoleIds.add(role.id);
                                } else {
                                  _selectedRoleIds.remove(role.id);
                                }
                              });
                            },
                            secondary: Icon(
                              Icons.shield_outlined,
                              color: role.isActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              GetX<UsersController>(
                builder: (controller) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: isMobile
                              ? const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8)
                              : null,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'Assign Roles',
                        onPressed: _submit,
                        isLoading: controller.isLoading.value,
                        width: isMobile ? 110 : null,
                        height: isMobile ? 36 : 48,
                        fontSize: isMobile ? 13 : 16,
                        padding: isMobile
                            ? const EdgeInsets.symmetric(horizontal: 12)
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          ),
        );
      },
      ),
    );
  }
}
