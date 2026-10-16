import 'package:dio/dio.dart';

/// Base class for every network failure the app can surface.
///
/// Sealed so callers can exhaustively switch over the possible failures:
///
/// ```dart
/// final message = switch (exception) {
///   NoInternetException() => 'You are offline.',
///   UnauthorizedException() => 'Please sign in again.',
///   NetworkException(:final message) => message,
/// };
/// ```
sealed class NetworkException implements Exception {
  const NetworkException({required this.message, this.statusCode});

  /// User-safe message.
  final String message;

  /// HTTP status code, when the failure came from a response.
  final int? statusCode;

  /// Maps a raw [DioException] onto the app's typed failures.
  factory NetworkException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.badResponse:
        final int? code = error.response?.statusCode;
        final String serverMessage = _extractMessage(error.response?.data);
        if (code == 400 || code == 422) {
          return BadRequestException(message: serverMessage, statusCode: code);
        }
        if (code == 401) {
          return UnauthorizedException(
            message: serverMessage,
            statusCode: code,
          );
        }
        if (code == 403) {
          return ForbiddenException(message: serverMessage, statusCode: code);
        }
        if (code == 404) {
          return NotFoundException(message: serverMessage, statusCode: code);
        }
        if (code != null && code >= 500) {
          return ServerException(message: serverMessage, statusCode: code);
        }
        return UnexpectedNetworkException(
          message: serverMessage,
          statusCode: code,
        );

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkTimeoutException();

      case DioExceptionType.cancel:
        return const RequestCancelledException();

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badCertificate:
        return const UnexpectedNetworkException(
          message: 'The server certificate could not be verified.',
        );

      // `default` (rather than `case unknown`) keeps this mapping compiling
      // when a future Dio release adds a new [DioExceptionType].
      default:
        return UnexpectedNetworkException(
          message: error.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  /// Pulls the most useful message out of a typical REST error body.
  static String _extractMessage(Object? data) {
    if (data is Map) {
      final Object? candidate =
          data['message'] ?? data['error'] ?? data['detail'] ?? data['title'];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return 'The server returned an unexpected response.';
  }

  @override
  String toString() =>
      '$runtimeType${statusCode == null ? '' : '($statusCode)'}: $message';
}

/// The device has no usable network connection.
final class NoInternetException extends NetworkException {
  const NoInternetException()
    : super(
        message: 'No internet connection. Check your network and try again.',
      );
}

/// The request took longer than the configured timeout.
final class NetworkTimeoutException extends NetworkException {
  const NetworkTimeoutException()
    : super(message: 'The connection timed out. Please try again.');
}

/// 400 / 422 — the payload was rejected by the server.
final class BadRequestException extends NetworkException {
  const BadRequestException({
    super.message = 'The request was invalid.',
    super.statusCode,
  });
}

/// 401 — missing, expired or rejected credentials.
final class UnauthorizedException extends NetworkException {
  const UnauthorizedException({
    super.message = 'Your session has expired. Please sign in again.',
    super.statusCode,
  });
}

/// 403 — authenticated, but not allowed.
final class ForbiddenException extends NetworkException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode,
  });
}

/// 404 — the resource does not exist.
final class NotFoundException extends NetworkException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode,
  });
}

/// 5xx — the server failed.
final class ServerException extends NetworkException {
  const ServerException({
    super.message =
        'The server is unavailable right now. Please try again later.',
    super.statusCode,
  });
}

/// The request was cancelled locally (e.g. the screen was disposed).
final class RequestCancelledException extends NetworkException {
  const RequestCancelledException()
    : super(message: 'The request was cancelled.');
}

/// Anything that does not fit the categories above.
final class UnexpectedNetworkException extends NetworkException {
  const UnexpectedNetworkException({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
  });
}
