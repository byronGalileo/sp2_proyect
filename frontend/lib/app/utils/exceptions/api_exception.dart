/// Custom exception class for API errors with user-friendly messages
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? details;
  final dynamic originalError;

  ApiException({
    this.statusCode,
    required this.message,
    this.details,
    this.originalError,
  });

  /// Create ApiException from HTTP status code
  factory ApiException.fromStatusCode(
    int statusCode, {
    String? customMessage,
    String? details,
    dynamic originalError,
  }) {
    final message = customMessage ?? _getMessageForStatusCode(statusCode);
    return ApiException(
      statusCode: statusCode,
      message: message,
      details: details,
      originalError: originalError,
    );
  }

  /// Create ApiException from generic error
  factory ApiException.fromError(dynamic error, {String? customMessage}) {
    if (error is ApiException) {
      return error;
    }
    return ApiException(
      message: customMessage ?? 'An unexpected error occurred',
      details: error.toString(),
      originalError: error,
    );
  }

  /// Create ApiException from Dio error
  factory ApiException.fromDioError(dynamic error) {
    // We can't import Dio here to avoid circular dependency or extra dependency if this file is shared
    // But we can check the error type name or properties if needed, or just treat it as generic error
    // ideally we should import dio, but for now let's map it generically or check properties dynamically
    
    // If we can import dio, we would do:
    // if (error is DioException) { ... }
    
    // Since we are adding dio to the project, let's assume we can use dynamic checking or just wrap it
    // For a proper implementation, we should import dio in this file, but to avoid breaking other things
    // let's just extract the message if possible.
    
    String message = 'Network error occurred';
    int? statusCode;
    String? details;

    try {
      // dynamic access to DioException properties
      if (error.runtimeType.toString() == 'DioException') {
        final response = (error as dynamic).response;
        if (response != null) {
          statusCode = response.statusCode;
          if (response.data != null && response.data is Map) {
             message = response.data['detail'] ?? response.data['message'] ?? 'Error from server';
          }
        } else {
           message = (error as dynamic).message ?? 'Connection error';
        }
      }
    } catch (e) {
      // fallback
      details = error.toString();
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      details: details ?? error.toString(),
      originalError: error,
    );
  }

  /// Get user-friendly message for HTTP status code
  static String _getMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      // 4xx Client Errors
      case 400:
        return 'Bad request. Please check your input and try again.';
      case 401:
        return 'You don\'t have permission for this resource. Please log in again.';
      case 403:
        return 'Access forbidden. You don\'t have the necessary permissions.';
      case 404:
        return 'Resource not found. The requested item doesn\'t exist.';
      case 405:
        return 'Method not allowed. This action is not permitted.';
      case 408:
        return 'Request timeout. Please try again.';
      case 409:
        return 'Conflict. This resource already exists or conflicts with another.';
      case 410:
        return 'Resource no longer available.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please slow down and try again later.';

      // 5xx Server Errors
      case 500:
        return 'Internal server error. Please try again later.';
      case 501:
        return 'Not implemented. This feature is not available yet.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';

      // Default cases
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'Client error ($statusCode). Please check your request.';
        } else if (statusCode >= 500) {
          return 'Server error ($statusCode). Please try again later.';
        }
        return 'Request failed with status code $statusCode.';
    }
  }

  /// Get specific message for common operations
  static String getOperationMessage(String operation, int statusCode) {
    final operationMessages = {
      'create': {
        401: 'You don\'t have permission to create this resource.',
        403: 'Access forbidden. You cannot create this resource.',
        409: 'This resource already exists.',
        422: 'Invalid data. Please check your input.',
      },
      'update': {
        401: 'You don\'t have permission to update this resource.',
        403: 'Access forbidden. You cannot modify this resource.',
        404: 'Resource not found. Cannot update a non-existent item.',
        422: 'Invalid data. Please check your input.',
      },
      'delete': {
        401: 'You don\'t have permission to delete this resource.',
        403: 'Access forbidden. You cannot delete this resource.',
        404: 'Resource not found. Cannot delete a non-existent item.',
      },
      'fetch': {
        401: 'You don\'t have permission to view this resource.',
        403: 'Access forbidden. You cannot access this resource.',
        404: 'Resource not found.',
      },
    };

    return operationMessages[operation]?[statusCode] ??
        _getMessageForStatusCode(statusCode);
  }

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      return '$message\nDetails: $details';
    }
    return message;
  }

  /// Get a short version of the message (without details)
  String get shortMessage => message;

  /// Check if this is an authentication error
  bool get isAuthError => statusCode == 401;

  /// Check if this is a permission error
  bool get isPermissionError => statusCode == 403;

  /// Check if this is a not found error
  bool get isNotFoundError => statusCode == 404;

  /// Check if this is a validation error
  bool get isValidationError => statusCode == 422 || statusCode == 400;

  /// Check if this is a server error
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Check if this is a client error
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;
}
