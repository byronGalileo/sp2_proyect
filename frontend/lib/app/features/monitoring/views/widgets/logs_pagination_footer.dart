import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../controllers/logs_controller.dart';

class LogsPaginationFooter extends StatelessWidget {
  final LogsController controller;

  const LogsPaginationFooter({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.logs.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(bodyColor: AppColors.textLight, displayColor: AppColors.textLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page size selector
              Row(
                children: [
                  const Text('Rows per page:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: controller.pageSize.value,
                    dropdownColor: AppColors.primaryDark,
                    style: const TextStyle(color: AppColors.textOnPrimary),
                    iconEnabledColor: AppColors.textLight,
                    underline: const SizedBox(),
                    items: controller.pageSizeOptions.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size', style: const TextStyle(color: AppColors.textOnPrimary)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.changePageSize(value);
                      }
                    },
                  ),
                ],
              ),
              // Page info and navigation
              Row(
                children: [
                  Text(
                    'Page ${controller.currentPageNumber} of ${controller.totalPages}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.textLight),
                    onPressed:
                        controller.hasPrevious ? controller.loadPreviousPage : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onPressed: controller.hasMore ? controller.loadNextPage : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
