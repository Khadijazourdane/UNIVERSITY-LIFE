import 'package:flutter/foundation.dart';

import '../../students/models/student_model.dart';
import '../../students/services/teacher_student_service.dart';
import '../models/attendance_session_model.dart';
import '../services/teacher_attendance_service.dart';

class TeacherAttendanceProvider extends ChangeNotifier {
  TeacherAttendanceProvider(this._service, this._studentService);

  final TeacherAttendanceService _service;
  final TeacherStudentService _studentService;

  List<AttendanceSessionModel> sessions = [];
  AttendanceSessionModel? selectedSession;
  List<StudentModel> students = [];
  final Map<String, bool> _present = {};
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load(String moduleId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      students = await _studentService.fetchStudents(moduleId);
      sessions = await _service.fetchSessions(moduleId);
      if (sessions.isNotEmpty) {
        await _loadSession(sessions.first);
      }
    } catch (_) {
      error = 'Impossible de charger les séances.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> selectSession(AttendanceSessionModel session) async {
    await _loadSession(session);
    notifyListeners();
  }

  Future<void> _loadSession(AttendanceSessionModel session) async {
    selectedSession = session;
    final records = await _service.fetchRecords(session.id);
    _present.clear();
    // Par défaut, tout le monde est présent tant que l'appel n'est pas fait.
    for (final s in students) {
      _present[s.id] = true;
    }
    for (final r in records) {
      _present[r.studentId] = r.isPresent;
    }
  }

  bool isPresent(String studentId) => _present[studentId] ?? true;

  void setPresent(String studentId, bool value) {
    _present[studentId] = value;
    notifyListeners();
  }

  Future<bool> save() async {
    final session = selectedSession;
    if (session == null) return false;
    isSaving = true;
    notifyListeners();
    try {
      await _service.saveRecords(session.id, _present);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      error = 'L\'enregistrement a échoué.';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
