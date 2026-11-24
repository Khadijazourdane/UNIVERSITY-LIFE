import 'package:university_life/features/admin/services/admin_api.dart';

class Filiere {
  const Filiere({required this.id, required this.name, this.description = ''});

  factory Filiere.fromJson(Map<String, dynamic> json) => Filiere(
    id: asText(json['id']),
    name: asText(json['name']),
    description: asText(json['description']),
  );

  final String id;
  final String name;
  final String description;
}
