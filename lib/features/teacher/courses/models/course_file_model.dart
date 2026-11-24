/// Support pédagogique PDF publié par le professeur.
class CourseFileModel {
  const CourseFileModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.fileName,
    required this.group,
    required this.publishedAt,
  });

  final String id;
  final String moduleId;
  final String title;
  final String fileName;
  final String group;
  final DateTime publishedAt;
}
