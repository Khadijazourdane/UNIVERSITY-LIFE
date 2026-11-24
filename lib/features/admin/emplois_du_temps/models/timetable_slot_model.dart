import 'package:university_life/features/admin/services/admin_api.dart';
class TimetableSlot {
  const TimetableSlot({
    required this.id,
    required this.groupId,
    required this.assignmentId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.groupName = '',
    this.assignmentLabel = '',
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
    id: asText(json['id']),
    groupId: asText(json['groupId']),
    assignmentId: asText(json['assignmentId']),
    day: asText(json['day']),
    startTime: asText(json['startTime']),
    endTime: asText(json['endTime']),
    room: asText(json['room']),
    groupName: asText(json['groupName']),
    assignmentLabel: asText(json['assignmentLabel']),
  );

  final String id;
  final String groupId;
  final String assignmentId;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String groupName;
  final String assignmentLabel;
}
