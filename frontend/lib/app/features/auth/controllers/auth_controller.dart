import 'package:get/get.dart';
import '../../../models/user.dart';
import '../../../utils/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final _isLoading = false.obs;
  final _isAuthenticated = false.obs;
  final _errorMessage = ''.obs;
  final Rx<User?> _user = Rx<User?>(null);

  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  String? get errorMessage => _errorMessage.value.isEmpty ? null : _errorMessage.value;
  User? get user => _user.value;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      _isLoading.value = true;
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        final currentUser = await _authService.getCurrentUser();
        if (currentUser != null) {
          _user.value = currentUser;
          _isAuthenticated.value = true;
        } else {
          _isAuthenticated.value = false;
        }
      } else {
        _isAuthenticated.value = false;
      }
    } catch (e) {
      _isAuthenticated.value = false;
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final response = await _authService.login(
        username: username,
        password: password,
      );

      if (response.success && response.data != null) {
        _user.value = response.data!.user;
        _isAuthenticated.value = true;
        return true;
      } else {
        _errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Login failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      if (response.success && response.data != null) {
        _user.value = response.data!.user;
        _isAuthenticated.value = true;
        return true;
      } else {
        _errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Registration failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading.value = true;
      await _authService.logout();
      _user.value = null;
      _isAuthenticated.value = false;
      _errorMessage.value = '';
    } catch (e) {
      _errorMessage.value = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
