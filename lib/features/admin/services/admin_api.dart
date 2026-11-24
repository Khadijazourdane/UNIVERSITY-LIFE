import 'package:dio/dio.dart';


String asText(Object? value) => value?.toString() ?? '';
class AdminApi {
  AdminApi({Dio? dio})
      : _dio =
      dio ??
          Dio(
            BaseOptions(
              baseUrl: 'http://127.0.0.1:3000',
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );

  static final AdminApi shared = AdminApi();

  final Dio _dio;

  Future<List<T>> fetchAll<T>(
      String path,
      T Function(Map<String, dynamic> json) fromJson,
      ) async {
    final response = await _dio.get<List<dynamic>>(path);
    final items = response.data;

    if (items == null) {
      throw FormatException('Liste manquante pour $path.');
    }

    return [
      for (final item in items)
        fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)),
    ];
  }

  Future<void> post(String path, Map<String, Object?> body) async {
    await _dio.post<void>(path, data: body);
  }

  Future<void> put(String path, Map<String, Object?> body) async {
    await _dio.put<void>(path, data: body);
  }

  Future<void> delete(String path) async {
    await _dio.delete<void>(path);
  }
}
