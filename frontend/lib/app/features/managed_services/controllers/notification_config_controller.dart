import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/notification_config.dart';
import '../../../utils/services/notification_service.dart';
import '../../../utils/exceptions/api_exception.dart';
import '../../../config/themes/app_theme.dart';

class NotificationConfigController extends GetxController {
  final NotificationService _service = NotificationService();

  final Rx<NotificationConfig?> config = Rx<NotificationConfig?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Form fields
  final RxString selectedProvider = 'twilio'.obs;
  final RxInt cooldownMinutes = 5.obs;

  Future<void> loadConfig(String serviceId, String host) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      config.value = null; // Clear previous config to avoid showing stale data
      selectedProvider.value = 'twilio'; // Reset to default
      cooldownMinutes.value = 5; // Reset to default
      
      config.value = await _service.getConfig(serviceId, host);
      if (config.value != null) {
        selectedProvider.value = config.value!.smsProvider;
        cooldownMinutes.value = config.value!.cooldownMinutes;
      }
    } on ApiException catch (e) {
      // If 404 or "not found" message, it means no config exists yet, which is fine
      if (e.statusCode == 404 || 
          e.message.contains('404') || 
          e.message.toLowerCase().contains('not found')) {
        config.value = null;
      } else {
        errorMessage.value = e.message;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createConfig(String serviceId, String host) async {
    try {
      isLoading.value = true;
      final newConfig = NotificationConfig(
        serviceName: serviceId,
        host: host,
        smsProvider: selectedProvider.value,
        cooldownMinutes: cooldownMinutes.value,
        contacts: [],
      );
      await _service.createConfig(newConfig);
      await loadConfig(serviceId, host);
      Get.snackbar(
        'Success',
        'Notification configuration created',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create configuration: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSettings(String serviceId, String host) async {
    try {
      isLoading.value = true;
      await _service.updateSettings(
        serviceId,
        host,
        selectedProvider.value,
        cooldownMinutes.value,
      );
      await loadConfig(serviceId, host);
      Get.snackbar(
        'Success',
        'Notification configuration updated',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update notification configuration: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addContact(String serviceId, String host, Contact contact) async {
    try {
      isLoading.value = true;
      await _service.addContact(serviceId, host, contact);
      await loadConfig(serviceId, host);
      Get.back(); // Close add contact dialog
      Get.snackbar(
        'Success',
        'Contact added',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add contact: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateContact(
      String serviceId, String host, String originalName, Contact contact) async {
    try {
      isLoading.value = true;
      await _service.updateContact(serviceId, host, originalName, contact);
      await loadConfig(serviceId, host);
      Get.back(); // Close edit contact dialog
      Get.snackbar(
        'Success',
        'Contact updated',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update contact: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteContact(
      String serviceId, String host, String contactName) async {
    try {
      isLoading.value = true;
      await _service.deleteContact(serviceId, host, contactName);
      await loadConfig(serviceId, host);
      Get.snackbar(
        'Success',
        'Contact deleted',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete contact: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
