part of 'app_pages.dart';

/// used to switch pages
class Routes {
  static const splash = _Paths.splash;
  static const login = _Paths.login;
  static const register = _Paths.register;
  static const home = _Paths.home;
  static const dashboard = _Paths.dashboard;
  static const profile = _Paths.profile;
  static const roles = _Paths.roles;
  static const users = _Paths.users;
  static const hosts = _Paths.hosts;
  static const managedServices = _Paths.managedServices;
  static const servicesStatus = _Paths.servicesStatus;
  static const logs = _Paths.logs;
}

/// contains a list of route names.
// made separately to make it easier to manage route naming
class _Paths {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const roles = '/admin/roles';
  static const users = '/admin/users';
  static const hosts = '/services/hosts';
  static const managedServices = '/services/managed-services';
  static const servicesStatus = '/monitoring/services-status';
  static const logs = '/monitoring/logs';
}
