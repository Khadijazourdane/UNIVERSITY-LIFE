/// Séance d'un module pour laquelle on fait l'appel.
class AttendanceSessionModel {
  const AttendanceSessionModel({
    required this.id,
    required this.label,
    required this.date,
  });

  final String id;
  final String label;
  final DateTime date;
}
