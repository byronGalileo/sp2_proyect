import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'responsive_builder.dart';

/// A reusable wrapper component that provides consistent layout with sidebar
/// across all screens in the application.
///
/// This component handles:
/// - Responsive layouts (mobile, tablet, desktop)
/// - Sidebar integration with drawer for mobile/tablet
/// - Consistent flex ratios and spacing
/// - Proper scaffold key management for drawer
///
/// Usage:
/// ```dart
/// BaseScreenWrapper(
///   title: 'My Screen',
///   child: MyScreenContent(),
/// )
/// ```
class BaseScreenWrapper extends StatefulWidget {
  /// The main content of the screen
  final Widget child;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional app bar actions (shown in mobile/tablet)
  final List<Widget>? appBarActions;

  /// Whether to show the sidebar in desktop mode (default: true)
  final bool showSidebar;

  /// Custom sidebar widget (defaults to AppSidebar)
  final Widget? customSidebar;

  const BaseScreenWrapper({
    Key? key,
    required this.child,
    this.floatingActionButton,
    this.appBarActions,
    this.showSidebar = true,
    this.customSidebar,
  }) : super(key: key);

  @override
  State<BaseScreenWrapper> createState() => _BaseScreenWrapperState();
}

class _BaseScreenWrapperState extends State<BaseScreenWrapper> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: !ResponsiveBuilder.isDesktop(context) && widget.showSidebar
          ? Drawer(
              child: SafeArea(
                child: SingleChildScrollView(
                  child: widget.customSidebar ??
                      AppSidebar(
                        onItemSelected: () {
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return widget.child;
          },
          tabletBuilder: (context, constraints) {
            if (!widget.showSidebar) {
              return widget.child;
            }
            return _buildLayoutWithSidebar(context, constraints);
          },
          desktopBuilder: (context, constraints) {
            if (!widget.showSidebar) {
              return widget.child;
            }
            return _buildLayoutWithSidebar(context, constraints);
          },
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildLayoutWithSidebar(BuildContext context, BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar section
        Flexible(
          flex: constraints.maxWidth > 1350 ? 3 : 4,
          child: SingleChildScrollView(
            child: widget.customSidebar ??
                AppSidebar(
                  onItemSelected: () {
                    _scaffoldKey.currentState?.closeDrawer();
                  },
                ),
          ),
        ),
        // Divider
        const VerticalDivider(width: 1),
        // Content section
        Flexible(
          flex: constraints.maxWidth > 1350 ? 10 : 9,
          child: widget.child,
        ),
      ],
    );
  }

  /// Helper method to get the scaffold key for opening drawer from child widgets
  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
}

/// Helper widget to be used inside BaseScreenWrapper children
/// to show a menu button that opens the drawer on mobile/tablet
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBuilder.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
    );
  }
}
