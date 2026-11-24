import 'package:university_life/features/admin/services/admin_api.dart';
class Student {
  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.groupId = '',
    this.groupName = '',
    this.filiereName = '',
  });
  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: asText(json['id']),
    firstName: asText(json['firstName']),
    lastName: asText(json['lastName']),
    email: asText(json['email']),
    groupId: asText(json['groupId']),
    groupName: asText(json['groupName']),
    filiereName: asText(json['filiereName']),
  );
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String groupId;
  final String groupName;
  final String filiereName;
  String get fullName => '$firstName $lastName'.trim();
}
