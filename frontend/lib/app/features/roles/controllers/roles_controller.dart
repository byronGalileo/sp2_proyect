import 'package:get/get.dart';
import '../../../models/role.dart';
import '../../../models/permission.dart';
import '../../../utils/services/role_service.dart';

class RolesController extends GetxController {
  final RoleService _roleService = RoleService();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isLoadingPermissions = false.obs;
  final RxList<Role> roles = <Role>[].obs;
  final RxList<Role> filteredRoles = <Role>[].obs;
  final RxList<Permission> availablePermissions = <Permission>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRoles();
    fetchAvailablePermissions();
  }

  /// Fetch all roles
  Future<void> fetchRoles() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final fetchedRoles = await _roleService.getRoles();
      
      roles.value = fetchedRoles;
      filteredRoles.value = fetchedRoles;
    } catch (e) {
      errorMessage.value = e.toString();
      
      Get.snackbar(
        'Error',
        'Failed to load roles: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch all available permissions
  Future<void> fetchAvailablePermissions() async {
    try {
      isLoadingPermissions.value = true;
      final permissions = await _roleService.getPermissions();
      availablePermissions.value = permissions;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load permissions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
    } finally {
      isLoadingPermissions.value = false;
    }
  }

  /// Search/filter roles
  void searchRoles(String query) {
    searchQuery.value = query.toLowerCase();

    if (query.isEmpty) {
      filteredRoles.value = roles;
    } else {
      filteredRoles.value = roles.where((role) {
        return role.name.toLowerCase().contains(searchQuery.value) ||
            role.displayName.toLowerCase().contains(searchQuery.value) ||
            (role.description?.toLowerCase().contains(searchQuery.value) ?? false);
      }).toList();
    }
  }

  /// Create new role
  Future<bool> createRole({
    required String name,
    required String displayName,
    String? description,
    required List<int> permissionIds,
    bool isActive = true,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _roleService.createRole(
        name: name,
        displayName: displayName,
        description: description,
        permissionIds: permissionIds,
        isActive: isActive,
      );

      Get.snackbar(
        'Success',
        'Role created successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );

      // Refresh roles list
      await fetchRoles();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to create role: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing role
  Future<bool> updateRole({
    required int roleId,
    required String name,
    required String displayName,
    String? description,
    required List<int> permissionIds,
    required bool isActive,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _roleService.updateRole(
        roleId: roleId,
        name: name,
        displayName: displayName,
        description: description,
        permissionIds: permissionIds,
        isActive: isActive,
      );

      Get.snackbar(
        'Success',
        'Role updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh roles list
      await fetchRoles();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update role: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get role by ID
  Future<Role?> getRoleById(int roleId) async {
    try {
      return await _roleService.getRoleById(roleId);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load role: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
      return null;
    }
  }
}
