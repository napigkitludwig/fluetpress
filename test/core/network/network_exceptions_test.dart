import 'package:dio/dio.dart';
import 'package:fluetpress/core/network/network_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RequestOptions options() => RequestOptions(path: '/auth/login');

  Response<dynamic> response(int statusCode, {Object? data}) =>
      Response<dynamic>(
        requestOptions: options(),
        statusCode: statusCode,
        data: data,
      );

  DioException badResponse(int statusCode, {Object? data}) => DioException(
    requestOptions: options(),
    type: DioExceptionType.badResponse,
    response: response(statusCode, data: data),
  );

  group('NetworkException.fromDio', () {
    test('maps 401 to UnauthorizedException', () {
      final NetworkException exception = NetworkException.fromDio(
        badResponse(401, data: <String, dynamic>{'message': 'Token expired'}),
      );

      expect(exception, isA<UnauthorizedException>());
      expect(exception.message, 'Token expired');
      expect(exception.statusCode, 401);
    });

    test('maps 400 and 422 to BadRequestException', () {
      expect(
        NetworkException.fromDio(badResponse(400)),
        isA<BadRequestException>(),
      );
      expect(
        NetworkException.fromDio(badResponse(422)),
        isA<BadRequestException>(),
      );
    });

    test('maps 403, 404 and 5xx to their typed failures', () {
      expect(
        NetworkException.fromDio(badResponse(403)),
        isA<ForbiddenException>(),
      );
      expect(
        NetworkException.fromDio(badResponse(404)),
        isA<NotFoundException>(),
      );
      expect(
        NetworkException.fromDio(badResponse(503)),
        isA<ServerException>(),
      );
    });

    test('falls back for unexpected status codes', () {
      expect(
        NetworkException.fromDio(badResponse(418)),
        isA<UnexpectedNetworkException>(),
      );
    });

    test('maps timeouts', () {
      final NetworkException exception = NetworkException.fromDio(
        DioException(
          requestOptions: options(),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      expect(exception, isA<NetworkTimeoutException>());
    });

    test('maps connection errors to NoInternetException', () {
      final NetworkException exception = NetworkException.fromDio(
        DioException(
          requestOptions: options(),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(exception, isA<NoInternetException>());
    });

    test('extracts a plain string body', () {
      final NetworkException exception = NetworkException.fromDio(
        badResponse(500, data: 'database is on fire'),
      );

      expect(exception.message, 'database is on fire');
    });

    test('falls back to a generic message when the body is useless', () {
      final NetworkException exception = NetworkException.fromDio(
        badResponse(500, data: <String, dynamic>{'unexpected': true}),
      );

      expect(exception.message, isNotEmpty);
      expect(exception.statusCode, 500);
    });
  });
}
