import 'package:university_life/features/admin/services/admin_api.dart';

class Teacher {
  const Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.speciality = '',
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
    id: asText(json['id']),
    firstName: asText(json['firstName']),
    lastName: asText(json['lastName']),
    email: asText(json['email']),
    speciality: asText(json['speciality']),
  );

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String speciality;

  String get fullName => '$firstName $lastName'.trim();
}
