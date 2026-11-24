import 'package:dio/dio.dart';

import 'package:university_life/core/config/app_config.dart';

/// Shared Dio configuration. It does not define endpoints or log payloads.
class ApiClient {
  factory ApiClient({required Uri baseUri}) {
    _validateBaseUri(baseUri);
    return ApiClient._(Dio(_createOptions(baseUri)));
  }

  factory ApiClient.fromConfig() => ApiClient(baseUri: AppConfig.apiBaseUri);

  ApiClient._(this._dio);

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  final Dio _dio;

  Dio get dio => _dio;

  static BaseOptions _createOptions(Uri baseUri) {
    return BaseOptions(
      baseUrl: baseUri.toString(),
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      responseType: ResponseType.plain,
    );
  }

  static void _validateBaseUri(Uri baseUri) {
    if (!baseUri.isAbsolute ||
        !const {'http', 'https'}.contains(baseUri.scheme) ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        baseUri,
        'baseUri',
        'Provide an absolute HTTP(S) base URL without embedded credentials.',
      );
    }
  }
}
