import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A helper class to show consistent snackbar notifications.
class SnackbarHelper {
  /// Shows a success snackbar.
  ///
  /// [title] is the title of the snackbar, defaults to 'Success'.
  /// [message] is the main content of the snackbar.
  static void showSuccess({
    String title = 'Success',
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: (Colors.green[100] ?? Colors.green).withAlpha(204),
      colorText: Colors.green[900],
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Shows an error snackbar.
  ///
  /// [title] is the title of the snackbar, defaults to 'Error'.
  /// [message] is the main content of the snackbar.
  static void showError({
    String title = 'Error',
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      // Use withAlpha to avoid deprecation warnings from some linters. (0.8 * 255 = 204)
      backgroundColor: (Colors.red[100] ?? Colors.red).withAlpha(204),
      colorText: Colors.red[900],
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Shows a warning snackbar.
  ///
  /// [title] is the title of the snackbar, defaults to 'Warning'.
  /// [message] is the main content of the snackbar.
  static void showWarning({
    String title = 'Warning',
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      // Use withAlpha to avoid deprecation warnings from some linters. (0.9 * 255 = 230)
      backgroundColor: (Colors.orange[100] ?? Colors.orange).withAlpha(230),
      colorText: Colors.orange[900],
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}