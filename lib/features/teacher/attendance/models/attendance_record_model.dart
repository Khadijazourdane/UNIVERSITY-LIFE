/// Présence d'un étudiant à une séance.
class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.studentId,
    required this.isPresent,
  });

  final String studentId;
  final bool isPresent;
}
