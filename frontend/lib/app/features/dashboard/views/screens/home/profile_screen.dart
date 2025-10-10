import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../shared_components/responsive_builder.dart';
import '../../../../../shared_components/app_sidebar.dart';
import 'profile_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: ResponsiveBuilder.isDesktop(context)
          ? null
          : Drawer(
              child: SafeArea(
                child: SingleChildScrollView(
                  child: const AppSidebar(),
                ),
              ),
            ),
      body: SafeArea(
        child: ResponsiveBuilder(
          mobileBuilder: (context, constraints) {
            return _buildMobileLayout(context, scaffoldKey);
          },
          tabletBuilder: (context, constraints) {
            return _buildTabletLayout(context, scaffoldKey);
          },
          desktopBuilder: (context, constraints) {
            return _buildDesktopLayout(context, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, scaffoldKey: scaffoldKey),
        const Expanded(child: ProfilePage()),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
    return Column(
      children: [
        _buildHeader(context, scaffoldKey: scaffoldKey),
        const Expanded(child: ProfilePage()),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: constraints.maxWidth > 1350 ? 3 : 4,
          child: SingleChildScrollView(
            controller: ScrollController(),
            child: const AppSidebar(),
          ),
        ),
        Flexible(
          flex: constraints.maxWidth > 1350 ? 10 : 9,
          child: SingleChildScrollView(
            controller: ScrollController(),
            child: Column(
              children: [
                _buildHeader(context),
                const ProfilePage(),
              ],
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height,
          child: const VerticalDivider(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {GlobalKey<ScaffoldState>? scaffoldKey}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (scaffoldKey != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
          Expanded(
            child: Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (scaffoldKey == null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
        ],
      ),
    );
  }
}
