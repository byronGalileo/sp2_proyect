import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../models/user.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';

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
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
          ),
          dataTextStyle:
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Roles')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '@${user.username}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
                            backgroundColor: AppColors.primaryBase.withOpacity(0.1),
                            label: Text(
                              role,
                              style: const TextStyle(fontSize: 10, color: AppColors.textOnPrimary),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
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
                icon: const Icon(EvaIcons.editOutline,
                    size: 18, color: AppColors.textSecondary),
                onPressed: () => onEdit(user),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(EvaIcons.shieldOutline,
                    size: 18, color: AppColors.info),
                onPressed: () => onAssignRoles(user),
                tooltip: 'Assign Roles',
              ),
              IconButton(
                icon: const Icon(EvaIcons.lockOutline,
                    size: 18, color: AppColors.warning),
                onPressed: () => onResetPassword(user),
                tooltip: 'Reset Password',
              ),
              IconButton(
                icon: Icon(
                  user.isActive
                      ? EvaIcons.closeCircleOutline
                      : EvaIcons.checkmarkCircle2Outline,
                  size: 18,
                  color: user.isActive ? AppColors.error : AppColors.success,
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
        color: (isActive ? AppColors.success : AppColors.textSecondary).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? AppColors.success : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
