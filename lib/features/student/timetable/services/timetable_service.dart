import 'package:dio/dio.dart';
import 'package:university_life/features/student/timetable/models/session_model.dart';

class TimetableService {
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:3000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<List<Session>> fetchSessions() async {
    final response = await _dio.get<List<dynamic>>('/student/timetable');
    final items = response.data;

    if (items == null) {
      throw const FormatException('Liste des séances manquante.');
    }

    return [
      for (final item in items)
        Session(
          course: item['course'] as String,
          day: item['day'] as String,
          startTime: item['startTime'] as String,
          endTime: item['endTime'] as String,
          room: item['room'] as String,
        ),
    ];
  }

  void close() {
    _dio.close(force: true);
  }
}
