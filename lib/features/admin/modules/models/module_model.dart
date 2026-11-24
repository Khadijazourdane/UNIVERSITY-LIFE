import 'package:university_life/features/admin/services/admin_api.dart';

class CourseModule {
  const CourseModule({
    required this.id,
    required this.name,
    required this.code,
    required this.filiereId,
    required this.semesterId,
    this.filiereName = '',
    this.semesterName = '',
  });

  factory CourseModule.fromJson(Map<String, dynamic> json) => CourseModule(
    id: asText(json['id']),
    name: asText(json['name']),
    code: asText(json['code']),
    filiereId: asText(json['filiereId']),
    semesterId: asText(json['semesterId']),
    filiereName: asText(json['filiereName']),
    semesterName: asText(json['semesterName']),
  );

  final String id;
  final String name;
  final String code;
  final String filiereId;
  final String semesterId;
  final String filiereName;
  final String semesterName;
}
