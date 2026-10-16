import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env_config.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'api_response.dart';
import 'network_exceptions.dart';

/// Signature of the callback invoked when the session cannot be recovered
/// (the refresh token was rejected, or there was none).
typedef SessionExpiredCallback = Future<void> Function();

/// Centralised HTTP client.
///
/// Wraps [Dio] with everything a client app needs on day one:
///
///  * a [BaseOptions] built from [EnvConfig] (base URL + timeouts + headers),
///  * automatic `Authorization: Bearer <token>` injection from secure storage,
///  * **JWT auto-refresh**: a `401` triggers a single refresh call; the original
///    request is then retried once with the new token. Concurrent 401s share a
///    single refresh (no refresh storms),
///  * request/response logging outside production (`pretty_dio_logger`),
///  * typed [NetworkException] mapping, so callers never see a raw
///    [DioException] and return [Result]s instead of throwing.
///
/// Usage:
/// ```dart
/// final Result<User> result = await apiClient.get<User>(
///   ApiEndpoints.profile,
///   decoder: ApiClient.jsonMap(User.fromJson),
/// );
/// ```
class ApiClient {
  ApiClient({required this._secureStorage, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: EnvConfig.instance.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );

    if (EnvConfig.instance.enableApiLogging) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          compact: true,
          maxWidth: 100,
        ),
      );
    }

    _refreshDio = Dio(_dio.options);
  }

  final Dio _dio;
  final SecureStorageService _secureStorage;

  /// Bare client (no interceptors) used only for the refresh call, so refreshing
  /// a token can never recurse into the refresh logic.
  late final Dio _refreshDio;

  /// Key marking a request that already survived one refresh attempt.
  static const String _retriedKey = 'fluetpress.retried';
  static const String _requiresAuthKey = 'fluetpress.requiresAuth';

  /// In-flight refresh, shared by every concurrent `401`.
  Future<String?>? _refreshInFlight;

  /// Called when the session could not be recovered. The bootstrapper points
  /// this at `AuthService.expireSession`, which clears the local session so the
  /// router sends the user back to the login screen.
  SessionExpiredCallback? onUnauthorized;

  /// The underlying client, exposed for advanced use (uploads, streams).
  Dio get raw => _dio;

  // --- Verb helpers ----------------------------------------------------------

  /// `GET [path]`, decoded with [decoder].
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
    bool authenticated = true,
  }) => request<T>(
    path: path,
    decoder: decoder,
    queryParameters: queryParameters,
    authenticated: authenticated,
  );

  /// `POST [path]`, decoded with [decoder].
  Future<Result<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
    bool authenticated = true,
  }) => request<T>(
    path: path,
    method: 'POST',
    data: data,
    queryParameters: queryParameters,
    decoder: decoder,
    authenticated: authenticated,
  );

  /// `PUT [path]`, decoded with [decoder].
  Future<Result<T>> put<T>(
    String path, {
    Object? data,
    required T Function(dynamic json) decoder,
    bool authenticated = true,
  }) => request<T>(
    path: path,
    method: 'PUT',
    data: data,
    decoder: decoder,
    authenticated: authenticated,
  );

  /// `DELETE [path]`, decoded with [decoder].
  Future<Result<T>> delete<T>(
    String path, {
    Object? data,
    required T Function(dynamic json) decoder,
    bool authenticated = true,
  }) => request<T>(
    path: path,
    method: 'DELETE',
    data: data,
    decoder: decoder,
    authenticated: authenticated,
  );

  /// Sends a request and wraps the outcome in a [Result].
  ///
  /// Nothing escapes as an exception: transport failures become
  /// [NetworkException]s inside a `Failure`.
  Future<Result<T>> request<T>({
    required String path,
    required T Function(dynamic json) decoder,
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    try {
      final Response<dynamic> response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          extra: <String, dynamic>{_requiresAuthKey: authenticated},
        ),
      );
      return Success<T>(decoder(response.data));
    } on DioException catch (error) {
      final NetworkException exception = _toNetworkException(error);
      return Failure<T>(
        exception.message,
        statusCode: exception.statusCode,
        exception: exception,
      );
    } catch (error) {
      return Failure<T>('Unexpected error: $error');
    }
  }

  // --- Decoder helpers -------------------------------------------------------

  /// Adapts a `Map<String, dynamic>` parser into a decoder for [request].
  static T Function(dynamic) jsonMap<T>(
    T Function(Map<String, dynamic> json) parse,
  ) =>
      (dynamic data) =>
          parse((data as Map<dynamic, dynamic>).cast<String, dynamic>());

  /// Adapts a list parser into a decoder for [request].
  static T Function(dynamic) jsonList<T>(
    T Function(List<dynamic> items) parse,
  ) =>
      (dynamic data) => parse(data as List<dynamic>);

  /// A decoder for responses whose body is irrelevant (`201`, `204`, ...).
  static T Function(dynamic) ignore<T>(T value) =>
      (dynamic _) => value;

  // --- Interceptors ----------------------------------------------------------

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool requiresAuth = options.extra[_requiresAuthKey] as bool? ?? true;

    if (requiresAuth) {
      final String? token = await _secureStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = error.requestOptions;
    final bool isUnauthorized = error.response?.statusCode == 401;
    final bool alreadyRetried = request.extra[_retriedKey] == true;
    final bool isAuthEndpoint = _isAuthEndpoint(request.path);

    if (!isUnauthorized || alreadyRetried || isAuthEndpoint) {
      return handler.next(_mapError(error));
    }

    final String? refreshedToken = await _refreshAccessToken();
    if (refreshedToken == null) {
      // Refresh impossible or rejected: hand the session back to the app.
      await onUnauthorized?.call();
      return handler.next(_mapError(error));
    }

    try {
      final Response<dynamic> retried = await _dio.fetch<dynamic>(
        request.copyWith(
          headers: <String, dynamic>{
            ...request.headers,
            'Authorization': 'Bearer $refreshedToken',
          },
          extra: <String, dynamic>{...request.extra, _retriedKey: true},
        ),
      );
      return handler.resolve(retried);
    } on DioException catch (retryError) {
      return handler.next(_mapError(retryError));
    }
  }

  /// Single-flight refresh: concurrent callers await the same future.
  Future<String?> _refreshAccessToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _performRefresh() async {
    final String? refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final Response<dynamic> response = await _refreshDio.post<dynamic>(
        ApiEndpoints.refresh,
        data: <String, dynamic>{'refreshToken': refreshToken},
      );

      final dynamic body = response.data;
      if (body is! Map) {
        return null;
      }

      final String? accessToken = body['accessToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      await _secureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: (body['refreshToken'] as String?) ?? refreshToken,
      );
      return accessToken;
    } catch (_) {
      return null;
    }
  }

  bool _isAuthEndpoint(String path) =>
      path.contains(ApiEndpoints.refresh) || path.contains(ApiEndpoints.login);

  /// Ensures whatever reaches the caller carries a typed [NetworkException].
  DioException _mapError(DioException error) {
    if (error.error is NetworkException) {
      return error;
    }
    return error.copyWith(error: NetworkException.fromDio(error));
  }

  NetworkException _toNetworkException(DioException error) {
    final Object? mapped = error.error;
    if (mapped is NetworkException) {
      return mapped;
    }
    return NetworkException.fromDio(error);
  }

  /// Releases the underlying connections.
  void dispose() => _dio.close(force: true);
}
