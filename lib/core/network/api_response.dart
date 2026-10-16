import 'network_exceptions.dart';

/// A sealed, discriminated result of an operation that can fail.
///
/// Controllers and services return `Result<T>` instead of throwing, so views
/// can render a success or a failure deterministically:
///
/// ```dart
/// final Result<User> result = await repository.currentUser();
/// return switch (result) {
///   Success<User>(:final user) => ProfileView(user: user),
///   Failure<User>(:final message) => ErrorView(message: message),
/// };
/// ```
///
/// Use [Result.guard] to wrap a throwing call, or the flow helpers
/// ([when], [map], [dataOrNull], [errorOrNull]).
sealed class Result<T> {
  const Result();

  /// `true` for [Success].
  bool get isSuccess => this is Success<T>;

  /// `true` for [Failure].
  bool get isFailure => this is Failure<T>;

  /// The value on success, else `null`.
  T? get dataOrNull => switch (this) {
    Success<T>(:final T data) => data,
    Failure<T>() => null,
  };

  /// The message on failure, else `null`.
  String? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final String message) => message,
  };

  /// Folds the result into a single value.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure<T> failure) failure,
  }) => switch (this) {
    Success<T>(:final T data) => success(data),
    // The pattern variable must not shadow the `failure` callback above.
    Failure<T> failureResult => failure(failureResult),
  };

  /// Transforms a successful value, propagating failures untouched.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final T data) => Success<R>(transform(data)),
    Failure<T> failure => Failure<R>(
      failure.message,
      errorCode: failure.errorCode,
      statusCode: failure.statusCode,
      exception: failure.exception,
    ),
  };

  /// Runs [action] and captures its outcome.
  ///
  /// [NetworkException]s keep their typed message/status; anything else is
  /// reported with [fallbackMessage].
  static Future<Result<T>> guard<T>(
    Future<T> Function() action, {
    String fallbackMessage = 'Something went wrong. Please try again.',
  }) async {
    try {
      return Success<T>(await action());
    } on NetworkException catch (error) {
      return Failure<T>(
        error.message,
        statusCode: error.statusCode,
        exception: error,
      );
    } catch (error) {
      return Failure<T>('$fallbackMessage ($error)');
    }
  }
}

/// The operation completed successfully; [data] is the resulting value.
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success<$T>($data)';
}

/// The operation failed; [message] is safe to show to the user.
final class Failure<T> extends Result<T> {
  const Failure(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.exception,
  });

  /// Human readable, user-safe error message.
  final String message;

  /// HTTP status code when the failure came from the network.
  final int? statusCode;

  /// Machine readable code returned by the API (when provided).
  final String? errorCode;

  /// The underlying exception, kept for logging/analytics.
  final Object? exception;

  /// Whether this failure represents an expired/invalid session.
  bool get isUnauthorized =>
      statusCode == 401 || exception is UnauthorizedException;

  @override
  String toString() =>
      'Failure<$T>(${statusCode ?? errorCode ?? '-'}): $message';
}
