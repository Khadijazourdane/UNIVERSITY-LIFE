import 'package:university_life/features/admin/services/admin_api.dart';

class CourseSession {
  const CourseSession({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.teacherId,
    required this.groupId,
    required this.assignmentId,
    this.teacherName = '',
    this.groupName = '',
    this.assignmentLabel = '',
  });

  factory CourseSession.fromJson(Map<String, dynamic> json) => CourseSession(
    id: asText(json['id']),
    date: asText(json['date']),
    startTime: asText(json['startTime']),
    endTime: asText(json['endTime']),
    room: asText(json['room']),
    teacherId: asText(json['teacherId']),
    groupId: asText(json['groupId']),
    assignmentId: asText(json['assignmentId']),
    teacherName: asText(json['teacherName']),
    groupName: asText(json['groupName']),
    assignmentLabel: asText(json['assignmentLabel']),
  );

  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String room;
  final String teacherId;
  final String groupId;
  final String assignmentId;
  final String teacherName;
  final String groupName;
  final String assignmentLabel;
}
