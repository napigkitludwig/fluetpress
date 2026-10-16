import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

/// A signed-in session: who is authenticated, plus (when talking to a REST API)
/// the token pair that keeps them authenticated.
///
/// In local/offline mode the tokens are `null` — the persisted session only
/// records the user id, so it is the local `users` table that proves identity.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    /// The authenticated account.
    @UserJsonConverter() required User user,

    /// JWT access token (remote mode only).
    String? accessToken,

    /// JWT refresh token (remote mode only).
    String? refreshToken,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}

/// Maps the nested [User] through its own JSON mapping.
///
/// An explicit converter is required (rather than relying on
/// `explicitToJson`) because a freezed class nested from *another* library
/// cannot see the private `_$UserToJson` helper generated beside `User`.
class UserJsonConverter implements JsonConverter<User, Map<String, dynamic>> {
  const UserJsonConverter();

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User object) => object.toJson();
}
