import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/user.dart';
import '../../../models/role.dart';
import '../../../utils/services/user_service.dart';
import '../../../utils/services/role_service.dart';

class UsersController extends GetxController {
  final UserService _userService = UserService();
  final RoleService _roleService = RoleService();

  // Scaffold key for drawer
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Observable state
  final RxList<User> users = <User>[].obs;
  final RxList<Role> availableRoles = <Role>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;

  // Pagination
  final RxInt currentPage = 0.obs;
  final RxInt totalUsers = 0.obs;
  final int pageSize = 10;

  // Filters
  final Rx<bool?> filterIsActive = Rx<bool?>(true);

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadRoles();
  }

  /// Load users with current filters and pagination
  Future<void> loadUsers({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 0;
        users.clear();
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _userService.getUsers(
        skip: currentPage.value * pageSize,
        limit: pageSize,
        isActive: filterIsActive.value,
      );

      if (refresh) {
        users.value = response.users;
      } else {
        users.addAll(response.users);
      }

      totalUsers.value = response.total;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load users: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (isLoadingMore.value) return;
    if ((currentPage.value + 1) * pageSize >= totalUsers.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;
      await loadUsers();
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (isLoadingMore.value) return;
    if (currentPage.value <= 0) return;

    try {
      isLoadingMore.value = true;
      currentPage.value--;
      users.clear();
      await loadUsers();
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load available roles
  Future<void> loadRoles() async {
    try {
      availableRoles.value = await _roleService.getRoles();
    } catch (e) {
      // Silently fail for roles, not critical
      // Could use a logging framework here in production
    }
  }

  /// Create new user
  Future<bool> createUser({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;

      await _userService.createUser(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      Get.snackbar(
        'Success',
        'User created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh user list
      await loadUsers(refresh: true);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create user: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user
  Future<bool> updateUser({
    required int userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;

      final updatedUser = await _userService.updateUser(
        userId: userId,
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      // Update in list
      final index = users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        users[index] = updatedUser;
      }

      Get.snackbar(
        'Success',
        'User updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update user: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Activate user
  Future<void> activateUser(int userId) async {
    try {
      isLoading.value = true;

      final updatedUser = await _userService.activateUser(userId);

      // Update in list
      final index = users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        users[index] = updatedUser;
      }

      Get.snackbar(
        'Success',
        'User activated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to activate user: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Deactivate user
  Future<void> deactivateUser(int userId) async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Deactivate User'),
          content: Text(
                'Are you sure you want to deactivate this user',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isLoading.value = true;

      final updatedUser = await _userService.deactivateUser(userId);

      // Update in list
      final index = users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        users[index] = updatedUser;
      }

      Get.snackbar(
        'Success',
        'User deactivated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to deactivate user: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Assign roles to user
  Future<bool> assignRoles({
    required int userId,
    required List<int> roleIds,
  }) async {
    try {
      isLoading.value = true;

      final updatedUser = await _userService.assignRoles(
        userId: userId,
        roleIds: roleIds,
      );

      // Update in list
      final index = users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        users[index] = updatedUser;
      }

      Get.snackbar(
        'Success',
        'Roles assigned successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to assign roles: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset user password
  Future<bool> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;

      await _userService.resetPassword(
        userId: userId,
        newPassword: newPassword,
      );

      Get.snackbar(
        'Success',
        'Password reset successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reset password: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle filter for active users
  void toggleActiveFilter(bool? isActive) {
    filterIsActive.value = isActive;
    loadUsers(refresh: true);
  }

  /// Refresh users
  @override
  Future<void> refresh() async {
    await loadUsers(refresh: true);
  }

  // Computed properties
  bool get hasMore => (currentPage.value + 1) * pageSize < totalUsers.value;
  bool get hasPrevious => currentPage.value > 0;
  int get currentPageNumber => currentPage.value + 1;
  int get totalPages => (totalUsers.value / pageSize).ceil();
}
