import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/teacher/attendance/providers/teacher_attendance_provider.dart';
import 'features/teacher/attendance/services/teacher_attendance_service.dart';
import 'features/teacher/courses/providers/teacher_course_provider.dart';
import 'features/teacher/courses/services/teacher_course_service.dart';
import 'features/teacher/grades/providers/teacher_grade_provider.dart';
import 'features/teacher/grades/services/teacher_grade_service.dart';
import 'features/teacher/modules/providers/teacher_module_provider.dart';
import 'features/teacher/modules/services/teacher_module_service.dart';
import 'features/teacher/notifications/providers/teacher_notification_provider.dart';
import 'features/teacher/notifications/services/teacher_notification_service.dart';
import 'features/teacher/students/providers/teacher_student_provider.dart';
import 'features/teacher/students/services/teacher_student_service.dart';
import 'features/teacher/teacher_shell.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Les providers sont placés AU-DESSUS de MaterialApp : ainsi toutes les
    // routes poussées avec Navigator.push() y ont accès.
    return MultiProvider(
      providers: [
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
      ],
      child: MaterialApp(
        title: 'University Life',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const TeacherShell(),
      ),
    );
  }
}
