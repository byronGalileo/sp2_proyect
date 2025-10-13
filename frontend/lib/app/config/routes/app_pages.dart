import 'package:get/get.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/dashboard/views/screens/auth/login_screen.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/dashboard/views/screens/auth/register_screen.dart';
import '../../features/dashboard/views/screens/auth/splash_screen.dart';
import '../../features/dashboard/views/screens/dashboard_screen.dart';
import '../../features/dashboard/views/screens/home/profile_screen.dart';
import '../../features/roles/bindings/roles_binding.dart';
import '../../features/roles/views/screens/roles_screen.dart';
import '../../features/users/bindings/users_binding.dart';
import '../../shared_components/dashboard_wrapper.dart';
import '../../features/users/views/screens/users_screen.dart';
import '../../features/monitoring/bindings/services_binding.dart';
import '../../features/monitoring/views/screens/services_status_screen.dart';
import '../../features/monitoring/bindings/logs_binding.dart';
import '../../features/monitoring/views/screens/logs_screen.dart';
import '../../features/hosts/bindings/hosts_binding.dart';
import '../../features/hosts/views/screens/hosts_screen.dart';
import '../../features/managed_services/bindings/managed_services_binding.dart';
import '../../features/managed_services/views/screens/managed_services_screen.dart';

part 'app_routes.dart';

/// contains all configuration pages
class AppPages {
  /// when the app is opened, this page will be the first to be shown
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: _Paths.splash,
      page: () => const SplashScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.register,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.home,
      page: () => const DashboardWrapper(),
      bindings: [
        DashboardBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.dashboard,
      page: () => const DashboardWrapper(),
      bindings: [
        DashboardBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.profile,
      page: () => const ProfileScreen(),
      bindings: [
        DashboardBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.roles,
      page: () => const RolesScreen(),
      bindings: [
        DashboardBinding(),
        RolesBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.users,
      page: () => const UsersScreen(),
      bindings: [
        DashboardBinding(),
        UsersBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.hosts,
      page: () => const HostsScreen(),
      bindings: [
        DashboardBinding(),
        HostsBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.managedServices,
      page: () => const ManagedServicesScreen(),
      bindings: [
        DashboardBinding(),
        ManagedServicesBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.servicesStatus,
      page: () => const ServicesStatusScreen(),
      bindings: [
        DashboardBinding(),
        ServicesBinding(),
        AuthBinding(),
      ],
    ),
    GetPage(
      name: _Paths.logs,
      page: () => const LogsScreen(),
      bindings: [
        DashboardBinding(),
        LogsBinding(),
        AuthBinding(),
      ],
    ),
  ];
}
