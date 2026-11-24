import 'package:university_life/features/admin/services/admin_api.dart';
class Assignment {
  const Assignment({
    required this.id,
    required this.teacherId,
    required this.moduleId,
    this.teacherName = '',
    this.moduleName = '',
  });
  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: asText(json['id']),
    teacherId: asText(json['teacherId']),
    moduleId: asText(json['moduleId']),
    teacherName: asText(json['teacherName']),
    moduleName: asText(json['moduleName']),
  );
  final String id;
  final String teacherId;
  final String moduleId;
  final String teacherName;
  final String moduleName;

  String get label => '$moduleName · $teacherName';
}
