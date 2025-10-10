import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constans/app_constants.dart';
import 'auth_user_profile.dart';
import 'selection_button.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class AppSidebar extends StatelessWidget {
  final VoidCallback? onItemSelected;
  const AppSidebar({this.onItemSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: AuthUserProfile(),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SelectionButton(
              data: [
                SelectionButtonData(
                  activeIcon: EvaIcons.home,
                  icon: EvaIcons.homeOutline,
                  label: "Home",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.wifi,
                  icon: EvaIcons.wifi,
                  label: "Services",
                  totalNotif: 100,
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.monitor,
                  icon: EvaIcons.monitorOutline,
                  label: "Monitoring",
                  totalNotif: 20,
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.settings,
                  icon: EvaIcons.settingsOutline,
                  label: "Admin",
                  children: [
                    SelectionButtonData(
                      activeIcon: EvaIcons.person,
                      icon: EvaIcons.personOutline,
                      label: "Users",
                    ),
                    SelectionButtonData(
                      activeIcon: EvaIcons.shield,
                      icon: EvaIcons.shieldOutline,
                      label: "Roles",
                    ),
                    SelectionButtonData(
                      activeIcon: EvaIcons.settings2,
                      icon: EvaIcons.settingsOutline,
                      label: "Settings",
                    ),
                  ],
                ),
              ],
              onSelected: (index, value) {
                handleNavigation(value.label);
                onItemSelected?.call();
              },
            ),
          ),
          const Divider(
            indent: 20,
            thickness: 1,
            endIndent: 20,
            height: 60,
          ),
          const SizedBox(height: kSpacing),
          Padding(
            padding: const EdgeInsets.all(kSpacing),
            child: Text(
              "2025 Monitor lisence",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void handleNavigation(String label) {
    if (label == 'Roles') {
      Get.toNamed('/admin/roles');
    } else if (label == 'Users') {
      Get.toNamed('/admin/users');
    } else if (label == 'Settings') {
      Get.snackbar('Coming Soon', 'Settings will be available soon');
    } else if (label == 'Home') {
      Get.toNamed('/home');
    }
  }
}
