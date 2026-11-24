import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'attendance/providers/teacher_attendance_provider.dart';
import 'attendance/services/teacher_attendance_service.dart';
import 'courses/providers/teacher_course_provider.dart';
import 'courses/services/teacher_course_service.dart';
import 'grades/providers/teacher_grade_provider.dart';
import 'grades/services/teacher_grade_service.dart';
import 'modules/providers/teacher_module_provider.dart';
import 'modules/services/teacher_module_service.dart';
import 'notifications/providers/teacher_notification_provider.dart';
import 'notifications/services/teacher_notification_service.dart';
import 'students/providers/teacher_student_provider.dart';
import 'students/services/teacher_student_service.dart';

/// Providers de l'espace professeur.
///
/// À placer AU-DESSUS de `MaterialApp` (dans `app.dart`) : les écrans ouverts
/// avec `Navigator.push` sont des routes séparées et ne verraient pas des
/// providers placés plus bas, dans `TeacherShell`.
List<SingleChildWidget> buildTeacherProviders() {
  return [
    // Une seule instance de chaque service, partagée entre les providers.
    Provider(create: (_) => TeacherStudentService()),
    Provider(create: (_) => TeacherModuleService()),
    Provider(create: (_) => TeacherCourseService()),
    Provider(create: (_) => TeacherGradeService()),
    Provider(create: (_) => TeacherAttendanceService()),
    Provider(create: (_) => TeacherNotificationService()),

    ChangeNotifierProvider(
      create: (c) => TeacherModuleProvider(c.read<TeacherModuleService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => TeacherStudentProvider(c.read<TeacherStudentService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => TeacherCourseProvider(c.read<TeacherCourseService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => TeacherGradeProvider(
        c.read<TeacherGradeService>(),
        c.read<TeacherStudentService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => TeacherAttendanceProvider(
        c.read<TeacherAttendanceService>(),
        c.read<TeacherStudentService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => TeacherNotificationProvider(
        c.read<TeacherNotificationService>(),
      ),
    ),
  ];
}
