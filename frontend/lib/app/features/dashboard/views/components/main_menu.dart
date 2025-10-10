part of dashboard;

class _MainMenu extends StatelessWidget {
  const _MainMenu({
    required this.onSelected,
    this.menuKey,
    Key? key,
  }) : super(key: key);

  final Function(int index, SelectionButtonData value) onSelected;
  final Key? menuKey;

  @override
  Widget build(BuildContext context) {
    return SelectionButton(
      key: menuKey,
      data: [
        SelectionButtonData(
          activeIcon: EvaIcons.home,
          icon: EvaIcons.homeOutline,
          label: "Home",
        ),
        SelectionButtonData(
          activeIcon: EvaIcons.bell,
          icon: EvaIcons.bellOutline,
          label: "Notifications",
          totalNotif: 100,
        ),
        SelectionButtonData(
          activeIcon: EvaIcons.checkmarkCircle2,
          icon: EvaIcons.checkmarkCircle,
          label: "Task",
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
      onSelected: onSelected,
    );
  }
}
