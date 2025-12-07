import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../config/themes/app_theme.dart';
import '../../controllers/hosts_controller.dart';

class HostPaginationFooter extends StatelessWidget {
  final HostsController controller;

  const HostPaginationFooter({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.hosts.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.padding, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
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
}
