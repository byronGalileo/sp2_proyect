import 'dart:convert';
import 'package:http/http.dart' as http;
import '../exceptions/api_exception.dart';

/// Utility class to handle API responses consistently across the app
class ApiResponseHandler {
  /// Handle HTTP response and throw appropriate exceptions
  static T handleResponse<T>(
    http.Response response, {
    required T Function(dynamic json) parser,
    String operation = 'fetch',
    String? customSuccessMessage,
  }) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response
        if (response.body.isEmpty) {
          // If the parser can handle null, this will work.
          // Useful for 204 No Content responses.
          return parser(null);
        }
        final decodedBody = json.decode(response.body);
        return parser(decodedBody); // The parser is responsible for handling the structure
      } else {
        // Error response
        _handleErrorResponse(response, operation);
        throw ApiException.fromStatusCode(response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      print('ERROR: ${e}');
      print('Response: ${response.body}');
      throw ApiException.fromError(e);
    }
  }

  /// Handle error response and extract error details from body
  static void _handleErrorResponse(http.Response response, String operation) {
    String? details;

    try {
      if (response.body.isNotEmpty) {
        final errorBody = json.decode(response.body);

        // Try to extract error message from common API response formats
        if (errorBody is Map<String, dynamic>) {
          details = errorBody['detail'] ??
              errorBody['message'] ??
              errorBody['error'] ??
              errorBody['errors']?.toString();
        }
      }
    } catch (e) {
      // If we can't parse the error body, use the raw body
      details = response.body.isNotEmpty ? response.body : null;
    }

    final message =
        ApiException.getOperationMessage(operation, response.statusCode);

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      details: details,
    );
  }

  /// Handle list response
  static List<T> handleListResponse<T>(
    http.Response response, {
    required T Function(dynamic json) itemParser,
    String operation = 'fetch',
  }) {
    return handleResponse<List<T>>(
      response,
      parser: (json) {
        if (json == null) {
          return [];
        }

        dynamic listData = json;

        // Handle cases where the list is nested under a 'data' key,
        // e.g., { "data": [...] } or { "data": { "environments": [...] } }
        if (listData is Map<String, dynamic> && listData.containsKey('data')) {
          listData = listData['data'];
        }

        // If 'data' was an object, look for a key that holds the list.
        if (listData is Map<String, dynamic>) {
          // Find the first value that is a list.
          final listValue = listData.values.firstWhere((v) => v is List, orElse: () => null);
          if (listValue != null) {
            listData = listValue;
          }
        }

        if (listData is! List) {
          throw ApiException(
            message: 'Invalid response format. Expected a list.',
            details: 'Response was not a list: ${listData.toString()}',
          );
        }
        return listData.map<T>((item) => itemParser(item)).toList();
      },
      operation: operation,
    );
  }

  /// Handle paginated response
  static Map<String, dynamic> handlePaginatedResponse(
    http.Response response, {
    String operation = 'fetch',
  }) {
    return handleResponse<Map<String, dynamic>>(
      response,
      parser: (json) {
        if (json == null || json is! Map<String, dynamic>) {
          throw ApiException(
            message: 'Invalid response format. Expected an object.',
            details: 'Response: ${json.toString()}',
          );
        }
        return json;
      },
      operation: operation,
    );
  }

  /// Handle empty success response (for operations that don't return data)
  static void handleEmptyResponse(
    http.Response response, {
    String operation = 'update',
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    _handleErrorResponse(response, operation);
  }

  /// Safe JSON decoder that handles empty responses
  static dynamic decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    try {
      return json.decode(response.body);
    } catch (e) {
      throw ApiException(
        message: 'Failed to parse server response',
        details: 'Invalid JSON: ${response.body}',
        originalError: e,
      );
    }
  }

  /// Check if response is successful
  static bool isSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Get error message from response
  static String getErrorMessage(http.Response response,
      {String operation = 'fetch'}) {
    try {
      if (response.body.isNotEmpty) {
        final errorBody = json.decode(response.body);
        if (errorBody is Map<String, dynamic>) {
          final detail = errorBody['detail'] ??
              errorBody['message'] ??
              errorBody['error'];
          if (detail != null) return detail.toString();
        }
      }
    } catch (_) {}

    return ApiException.getOperationMessage(operation, response.statusCode);
  }
}
