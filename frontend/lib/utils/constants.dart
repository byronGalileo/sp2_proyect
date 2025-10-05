// lib/utils/constants.dart
class AppConstants {
  // API Constants
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Validation Constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double buttonHeight = 48.0;

  // Session Constants
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration refreshTokenBuffer = Duration(minutes: 5);

  // Storage Keys
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String firstLaunchKey = 'first_launch';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

// lib/utils/extensions.dart
extension StringExtensions on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(this);
        }

  bool get isValidPassword {
    return length >= 8 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(this);
  }

  bool get isValidUsername {
    return length >= 3 && RegExp(r'^[a-zA-Z0-9_]+').hasMatch(this);
  }

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension DateTimeExtensions on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
}