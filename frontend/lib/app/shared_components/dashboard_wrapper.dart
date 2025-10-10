import 'package:daily_task/app/features/dashboard/views/screens/dashboard_screen.dart';
import 'package:daily_task/app/shared_components/app_sidebar.dart';
import 'package:daily_task/app/shared_components/responsive_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: !ResponsiveBuilder.isDesktop(context)
          ? Drawer(
              child: SafeArea(
                child: AppSidebar(
                  onItemSelected: () {
                    _scaffoldKey.currentState?.closeDrawer(); // Close drawer after item selection
                  },
                ),
              ),
            )
          : null,
      bottomNavigationBar: (ResponsiveBuilder.isDesktop(context) || kIsWeb)
          ? null
          : const _BottomNavbar(),
      body: SafeArea(
        child: DashboardScreen(
          onMenuButtonPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
    );
  }
}

class _BottomNavbar extends StatelessWidget {
  const _BottomNavbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
        color: Theme.of(context).cardColor,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [], // Add bottom nav items here if needed
      ),
    );
  }
}