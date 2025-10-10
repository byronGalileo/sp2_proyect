import 'package:daily_task/app/constans/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectionButtonData {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final int? totalNotif;
  final List<SelectionButtonData>? children;

  SelectionButtonData({
    required this.activeIcon,
    required this.icon,
    required this.label,
    this.totalNotif,
    this.children,
  });
}

class SelectionButton extends StatefulWidget {
  const SelectionButton({
    this.initialSelected = 0,
    required this.data,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  final int initialSelected;
  final List<SelectionButtonData> data;
  final Function(int index, SelectionButtonData value) onSelected;

  @override
  State<SelectionButton> createState() => _SelectionButtonState();
}

class _SelectionButtonState extends State<SelectionButton> {
  String? selectedLabel;
  final Map<int, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected >= 0 && widget.initialSelected < widget.data.length) {
      selectedLabel = widget.data[widget.initialSelected].label;
    }
  }

  List<Widget> _buildMenuItems(List<SelectionButtonData> items, {int level = 0, int? parentIndex}) {
    final List<Widget> widgets = [];

    for (int index = 0; index < items.length; index++) {
      final data = items[index];
      final hasChildren = data.children != null && data.children!.isNotEmpty;
      final itemIndex = level == 0 ? index : parentIndex;
      final isExpanded = _expandedItems[itemIndex ?? index] ?? false;
      final isSelected = selectedLabel == data.label;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            left: level > 0 ? 10.0 : 0,
            right: 10,
          ),
          child: _Button(
            selected: isSelected,
            onPressed: () {
              if (hasChildren) {
                setState(() {
                  _expandedItems[itemIndex ?? index] = !isExpanded;
                });
              } else {
                widget.onSelected(level == 0 ? index : (parentIndex ?? index), data);
                setState(() {
                  selectedLabel = data.label;
                });
              }
            },
            data: data,
            hasChildren: hasChildren,
            isExpanded: isExpanded,
          ),
        ),
      );

      // Add children if expanded
      if (hasChildren && isExpanded) {
        widgets.addAll(_buildMenuItems(data.children!, level: level + 1, parentIndex: itemIndex));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildMenuItems(widget.data));
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.selected,
    required this.data,
    required this.onPressed,
    this.hasChildren = false,
    this.isExpanded = false,
    Key? key,
  }) : super(key: key);

  final bool selected;
  final SelectionButtonData data;
  final Function() onPressed;
  final bool hasChildren;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          (!selected) ? null : Theme.of(context).primaryColor.withOpacity(.1),
      borderRadius: BorderRadius.circular(kBorderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: kSpacing / 2),
              Expanded(child: _buildLabel()),
              if (data.totalNotif != null)
                Padding(
                  padding: const EdgeInsets.only(left: kSpacing / 2),
                  child: _buildNotif(),
                ),
              if (hasChildren)
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 20,
                  color: (!selected)
                      ? kFontColorPallets[1]
                      : Theme.of(Get.context!).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(
      (!selected) ? data.icon : data.activeIcon,
      size: 20,
      color: (!selected)
          ? kFontColorPallets[1]
          : Theme.of(Get.context!).primaryColor,
    );
  }

  Widget _buildLabel() {
    return Text(
      data.label,
      style: TextStyle(
        color: (!selected)
            ? kFontColorPallets[1]
            : Theme.of(Get.context!).primaryColor,
        fontWeight: FontWeight.bold,
        letterSpacing: .8,
        fontSize: 14,
      ),
    );
  }

  Widget _buildNotif() {
    return (data.totalNotif == null || data.totalNotif! <= 0)
        ? Container()
        : Container(
            width: 30,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              (data.totalNotif! >= 100) ? "99+" : "${data.totalNotif}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          );
  }
}
