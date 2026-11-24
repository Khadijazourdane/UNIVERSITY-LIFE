import 'package:dio/dio.dart';
import 'package:university_life/features/student/grades/models/grade_model.dart';

class GradesService {
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:3000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<List<Grade>> fetchGrades() async {
    final response = await _dio.get<List<dynamic>>('/student/grades');
    final items = response.data;

    if (items == null) {
      throw const FormatException('Liste des notes manquante.');
    }

    return [
      for (final item in items)
        Grade(
          module: item['module'] as String,
          score: (item['score'] as num).toDouble(),
        ),
    ];
  }
}