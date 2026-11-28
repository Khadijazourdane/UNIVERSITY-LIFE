import 'package:dio/dio.dart';

enum ApiFailureKind { network, timeout, http, cancelled, unknown }

/// A safe summary of a Dio failure without request or response contents.
class ApiException implements Exception {
  const ApiException({required this.kind, this.statusCode, this.code});

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

    final data = exception.response?.data;
    final error = data is Map<String, dynamic> ? data['error'] : null;
    final code = error is Map<String, dynamic> ? error['code'] : null;
    return ApiException(
      kind: kind,
      statusCode: exception.response?.statusCode,
      code: code is String && RegExp(r'^[A-Z_]{1,64}$').hasMatch(code)
          ? code
          : null,
    );
  }

  final ApiFailureKind kind;
  final int? statusCode;
  final String? code;

  bool get isNetworkFailure =>
      kind == ApiFailureKind.network || kind == ApiFailureKind.timeout;

  @override
  String toString() => 'ApiException(kind: $kind, statusCode: $statusCode)';
}
