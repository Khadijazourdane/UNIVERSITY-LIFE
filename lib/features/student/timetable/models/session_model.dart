class Session {
  const Session({
    required this.course,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  final String course;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
}