import 'package:dio/dio.dart';

enum ApiFailureKind { network, timeout, http, cancelled, unknown }

/// A safe summary of a Dio failure without request or response contents.
class ApiException implements Exception {
  const ApiException({required this.kind, this.statusCode});

  factory ApiException.fromDioException(DioException exception) {
    final kind = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiFailureKind.timeout,
      DioExceptionType.connectionError => ApiFailureKind.network,
      DioExceptionType.badResponse => ApiFailureKind.http,
      DioExceptionType.cancel => ApiFailureKind.cancelled,
      _ => ApiFailureKind.unknown,
    };

    return ApiException(kind: kind, statusCode: exception.response?.statusCode);
  }

  final ApiFailureKind kind;
  final int? statusCode;

  bool get isNetworkFailure =>
      kind == ApiFailureKind.network || kind == ApiFailureKind.timeout;

  @override
  String toString() => 'ApiException(kind: $kind, statusCode: $statusCode)';
}
