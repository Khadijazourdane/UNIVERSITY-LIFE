import '../models/attendance_record_model.dart';
import '../models/attendance_session_model.dart';

/// Données fictives en mémoire (à remplacer par `ApiClient`).
class TeacherAttendanceService {
  final Map<String, Map<String, bool>> _recordsBySession = {};

  Future<List<AttendanceSessionModel>> fetchSessions(String moduleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      AttendanceSessionModel(
        id: '${moduleId}_1',
        label: 'Séance 1',
        date: DateTime(2026, 11, 17),
      ),
      AttendanceSessionModel(
        id: '${moduleId}_2',
        label: 'Séance 2',
        date: DateTime(2026, 11, 20),
      ),
    ];
  }

  Future<List<AttendanceRecordModel>> fetchRecords(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final records = _recordsBySession[sessionId] ?? {};
    return records.entries
        .map((e) => AttendanceRecordModel(studentId: e.key, isPresent: e.value))
        .toList();
  }

  Future<void> saveRecords(String sessionId, Map<String, bool> records) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _recordsBySession[sessionId] = Map<String, bool>.from(records);
  }
}
