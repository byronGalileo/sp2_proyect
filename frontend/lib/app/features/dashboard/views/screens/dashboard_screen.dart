library dashboard;

import 'package:daily_task/app/constans/app_constants.dart';
import 'package:daily_task/app/features/auth/controllers/auth_controller.dart';
import 'package:daily_task/app/shared_components/card_task.dart';
import 'package:daily_task/app/shared_components/header_text.dart';
import 'package:daily_task/app/shared_components/list_task_assigned.dart';
import 'package:daily_task/app/shared_components/list_task_date.dart';
import 'package:daily_task/app/shared_components/responsive_builder.dart';
import 'package:daily_task/app/shared_components/search_field.dart';
import 'package:daily_task/app/shared_components/selection_button.dart';
import 'package:daily_task/app/shared_components/simple_selection_button.dart';
import 'package:daily_task/app/shared_components/simple_user_profile.dart';
import 'package:daily_task/app/shared_components/task_progress.dart';
import 'package:daily_task/app/shared_components/user_profile.dart';
import 'package:daily_task/app/shared_components/auth_user_profile.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:daily_task/app/shared_components/app_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daily_task/app/utils/helpers/app_helpers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// controller
import '../../controllers/dashboard_controller.dart';

// model

// component
part '../components/bottom_navbar.dart';
part '../components/header_weekly_task.dart';
part '../components/main_menu.dart';
part '../components/task_menu.dart';
part '../components/member.dart';
part '../components/task_in_progress.dart';
part '../components/weekly_task.dart';
part '../components/task_group.dart';

class DashboardScreen extends GetView<DashboardController> {
  final VoidCallback? onMenuButtonPressed;
  const DashboardScreen({this.onMenuButtonPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobileBuilder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskContent(
                onPressedMenu: onMenuButtonPressed,
              ),
            ],
          ),
        );
      },
      tabletBuilder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: constraints.maxWidth > 800 ? 8 : 7,
              child: SingleChildScrollView(
                controller: ScrollController(),
                child: _buildTaskContent(
                  onPressedMenu: onMenuButtonPressed,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const VerticalDivider(),
            ),
          ],
        );
      },
      desktopBuilder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: constraints.maxWidth > 1350 ? 3 : 4,
              child: IntrinsicHeight(
                child: SingleChildScrollView(
                  child: AppSidebar(
                    onItemSelected: () {
                      onMenuButtonPressed?.call();
                    },
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Flexible(
              flex: constraints.maxWidth > 1350 ? 10 : 9,
              child: SingleChildScrollView(
                child: Material(
                  child: _buildTaskContent(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskContent({Function()? onPressedMenu}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing),
      child: Column(
        children: [
          const SizedBox(height: kSpacing),
          Row(
            children: [
              if (onPressedMenu != null)
                Padding(
                  padding: const EdgeInsets.only(right: kSpacing / 2),
                  child: IconButton(
                    onPressed: onPressedMenu,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
              Expanded(
                child: SearchField(
                  onSearch: controller.searchTask,
                  hintText: "Search Task .. ",
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacing),
          Row(
            children: [
              Expanded(
                child: HeaderText(
                  DateTime.now().formatdMMMMY(),
                ),
              ),
              const SizedBox(width: kSpacing / 2),
              SizedBox(
                width: 200,
                child: TaskProgress(data: controller.dataTask),
              ),
            ],
          ),
          const SizedBox(height: kSpacing),
          _TaskInProgress(data: controller.taskInProgress),
          const SizedBox(height: kSpacing * 2),
          const _HeaderWeeklyTask(),
          const SizedBox(height: kSpacing),
          _WeeklyTask(
            data: controller.weeklyTask,
            onPressed: controller.onPressedTask,
            onPressedAssign: controller.onPressedAssignTask,
            onPressedMember: controller.onPressedMemberTask,
          )
        ],
      ),
    );
  }
}
