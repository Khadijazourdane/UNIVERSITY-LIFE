import 'package:university_life/features/admin/services/admin_api.dart';

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.filiereId,
    this.filiereName = '',
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: asText(json['id']),
    name: asText(json['name']),
    filiereId: asText(json['filiereId']),
    filiereName: asText(json['filiereName']),
  );

  final String id;
  final String name;
  final String filiereId;
  final String filiereName;
}
