import 'package:dio/dio.dart';
import 'package:university_life/features/student/absences/models/absence_model.dart';

class AbsencesService {
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:3000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<List<Absence>> fetchAbsences() async {
    final response = await _dio.get<List<dynamic>>('/student/absences');
    final items = response.data;

    if (items == null) {
      throw const FormatException('Liste des absences manquante.');
    }

    return [
      for (final item in items)
        Absence(
          module: item['module'] as String,
          date: item['date'] as String,
          isJustified: item['isJustified'] as bool,
        ),
    ];
  }

  void close() {
    _dio.close(force: true);
  }
}