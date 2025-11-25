import 'package:flutter/material.dart';
import '../config/themes/app_theme.dart';
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
  /// The title of the screen, shown in the AppBar on mobile/tablet.
  final String? title;

  /// The main content of the screen
  final Widget child;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional app bar actions (shown in mobile/tablet)
  final List<Widget>? appBarActions;

  /// Whether to show the sidebar in desktop mode (default: true)
  final bool showSidebar;

  /// Whether to show the default header row in mobile/tablet mode (default: true)
  final bool showMobileHeader;

  /// Custom sidebar widget (defaults to AppSidebar)
  final Widget? customSidebar;

  const BaseScreenWrapper({
    Key? key,
    this.title,
    required this.child,
    this.floatingActionButton,
    this.appBarActions,
    this.showSidebar = true,
    this.showMobileHeader = true,
    this.customSidebar,
  }) : super(key: key);

  @override
  State<BaseScreenWrapper> createState() => _BaseScreenWrapperState();
}

class _BaseScreenWrapperState extends State<BaseScreenWrapper> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Determines if the permanent, fixed sidebar should be shown.
  /// This is true only on desktop layouts where the sidebar is enabled.
  bool get shouldShowPermanentSidebar => ResponsiveBuilder.isDesktop(context) && widget.showSidebar;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: null, // AppBar is now handled within the body for mobile/tablet
      drawer: !shouldShowPermanentSidebar && widget.showSidebar
          ? Drawer(
              backgroundColor: AppColors.primaryDark,
              child: SafeArea(
                child: widget.customSidebar ??
                    AppSidebar(
                      onItemSelected: () {
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Conditionally show the inline header ONLY if the permanent sidebar is hidden AND showMobileHeader is true.
            if (!shouldShowPermanentSidebar && widget.showMobileHeader)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Row(
                  children: [
                    const DrawerMenuButton(),
                    const SizedBox(width: 16),
                    if (widget.title != null)
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (widget.appBarActions != null) ...widget.appBarActions!,
                  ],
                ),
              ),
            // Main content area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Sidebar for desktop
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: shouldShowPermanentSidebar ? 300 : 0,
                    child: ClipRect(
                      child: widget.customSidebar ??
                          AppSidebar(
                            onItemSelected: () =>
                                _scaffoldKey.currentState?.closeDrawer(),
                          ),
                    ),
                  ),
                  if (shouldShowPermanentSidebar) const VerticalDivider(width: 1),
                  // Screen's child content
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
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
    // Find the BaseScreenWrapper's state to check if the sidebar is visible.
    final wrapperState = context.findAncestorStateOfType<_BaseScreenWrapperState>();
    
    // Calculate visibility directly to ensure it updates with MediaQuery changes in this context
    final showSidebar = wrapperState?.widget.showSidebar ?? true;
    final isDesktop = ResponsiveBuilder.isDesktop(context);
    final shouldShowPermanentSidebar = isDesktop && showSidebar;

    // If the permanent sidebar is visible, don't show the hamburger button.
    if (shouldShowPermanentSidebar) {
      return const SizedBox.shrink();
    }

    return IconButton( // Otherwise, show it to allow opening the drawer.
      icon: const Icon(Icons.menu, color: AppColors.textOnPrimary),
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
    );
  }
}
