import 'package:university_life/features/admin/services/admin_api.dart';

class Semester {
  const Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
    id: asText(json['id']),
    name: asText(json['name']),
    startDate: asText(json['startDate']),
    endDate: asText(json['endDate']),
  );

  final String id;
  final String name;
  final String startDate;
  final String endDate;
}
