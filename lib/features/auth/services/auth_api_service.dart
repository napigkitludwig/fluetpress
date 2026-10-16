import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../models/auth_session.dart';
import '../models/user.dart';

/// Thin, typed wrapper over the authentication REST endpoints.
///
/// It knows *nothing* about local storage or the session lifecycle — that is
/// [AuthService]'s job. Keeping the HTTP shape here means swapping the backend
/// (or mocking it in tests) touches exactly one file.
class AuthApiService {
  AuthApiService({required this._apiClient});

  final ApiClient _apiClient;

  /// `POST /auth/login`
  ///
  /// Expects `{ "accessToken": ..., "refreshToken": ..., "user": {...} }`.
  Future<Result<AuthSession>> signIn({
    required String username,
    required String password,
  }) {
    return _apiClient.post<AuthSession>(
      ApiEndpoints.login,
      authenticated: false,
      data: <String, dynamic>{'username': username, 'password': password},
      decoder: ApiClient.jsonMap(AuthSession.fromJson),
    );
  }

  /// `POST /auth/register`
  Future<Result<AuthSession>> register({
    required String username,
    required String password,
    String? email,
  }) {
    return _apiClient.post<AuthSession>(
      ApiEndpoints.register,
      authenticated: false,
      data: <String, dynamic>{
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      },
      decoder: ApiClient.jsonMap(AuthSession.fromJson),
    );
  }

  /// `GET /auth/me` — the profile behind the current access token.
  Future<Result<User>> profile() {
    return _apiClient.get<User>(
      ApiEndpoints.profile,
      decoder: ApiClient.jsonMap(User.fromJson),
    );
  }

  /// `POST /auth/forgot-password`
  Future<Result<bool>> forgotPassword({required String email}) {
    return _apiClient.post<bool>(
      ApiEndpoints.forgotPassword,
      authenticated: false,
      data: <String, dynamic>{'email': email},
      decoder: ApiClient.ignore(true),
    );
  }

  /// `POST /auth/logout` — invalidates the refresh token server-side.
  Future<Result<bool>> signOut() {
    return _apiClient.post<bool>(
      ApiEndpoints.logout,
      data: const <String, dynamic>{},
      decoder: ApiClient.ignore(true),
    );
  }
}
