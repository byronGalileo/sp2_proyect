import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../models/user.dart';

class UserTable extends StatelessWidget {
  final List<User> users;
  final Function(User) onEdit;
  final Function(User) onToggleActive;
  final Function(User) onAssignRoles;
  final Function(User) onResetPassword;

  const UserTable({
    super.key,
    required this.users,
    required this.onEdit,
    required this.onToggleActive,
    required this.onAssignRoles,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: const [
            DataColumn(
              label: Text('User', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Roles', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: users.map((user) => _buildDataRow(context, user)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, User user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${user.username}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(Text(user.phone ?? '-')),
        DataCell(
          SizedBox(
            width: 150,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: user.roles.isEmpty
                  ? [const Text('-')]
                  : user.roles
                      .map((role) => Chip(
                            label: Text(
                              role,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
            ),
          ),
        ),
        DataCell(_buildStatusChip(user.isActive)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(EvaIcons.editOutline, size: 18),
                onPressed: () => onEdit(user),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(EvaIcons.shieldOutline, size: 18),
                onPressed: () => onAssignRoles(user),
                tooltip: 'Assign Roles',
              ),
              IconButton(
                icon: const Icon(EvaIcons.lockOutline, size: 18),
                onPressed: () => onResetPassword(user),
                tooltip: 'Reset Password',
              ),
              IconButton(
                icon: Icon(
                  user.isActive
                      ? EvaIcons.closeCircleOutline
                      : EvaIcons.checkmarkCircle2Outline,
                  size: 18,
                ),
                onPressed: () => onToggleActive(user),
                tooltip: user.isActive ? 'Deactivate' : 'Activate',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade800 : Colors.grey.shade800,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
