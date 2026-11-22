import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/core/network/api_client.dart';
import 'package:university_life/core/network/api_exception.dart';

void main() {
  test('requires an absolute HTTP or HTTPS base URI', () {
    expect(
      () => ApiClient(baseUri: Uri.parse('file:///api')),
      throwsArgumentError,
    );
    expect(
      () => ApiClient(baseUri: Uri.parse('https://user:password@example.test')),
      throwsArgumentError,
    );
  });

  test('configures bounded timeouts without assuming a JSON response', () {
    final client = ApiClient(
      baseUri: Uri(scheme: 'https', host: 'example.test'),
    );
    addTearDown(client.dio.close);

    expect(client.dio.options.baseUrl, 'https://example.test');
    expect(client.dio.options.connectTimeout, ApiClient.connectTimeout);
    expect(client.dio.options.sendTimeout, ApiClient.sendTimeout);
    expect(client.dio.options.receiveTimeout, ApiClient.receiveTimeout);
    expect(client.dio.options.responseType, ResponseType.plain);
  });

  test('maps transport failures without retaining request data', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionTimeout,
      message: 'password=must-not-be-exposed',
    );

    final apiException = ApiException.fromDioException(exception);

    expect(apiException.kind, ApiFailureKind.timeout);
    expect(apiException.isNetworkFailure, isTrue);
    expect(apiException.toString(), isNot(contains('must-not-be-exposed')));
  });

  test('keeps HTTP status separate from transport errors', () {
    final request = RequestOptions(path: '/');
    final exception = DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 401,
        data: 'private-response-content',
      ),
    );

    final apiException = ApiException.fromDioException(exception);

    expect(apiException.kind, ApiFailureKind.http);
    expect(apiException.isNetworkFailure, isFalse);
    expect(apiException.statusCode, 401);
    expect(
      apiException.toString(),
      isNot(contains('private-response-content')),
    );
  });
}
