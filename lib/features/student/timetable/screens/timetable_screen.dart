import 'package:flutter/material.dart';
import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/student/timetable/models/session_model.dart';
import 'package:university_life/features/student/timetable/services/timetable_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const _demoDay = 'Lundi';

  final _service = TimetableService();
  late Future<List<Session>> _sessions;
  bool _showWeek = false;

  @override
  void initState() {
    super.initState();
    _sessions = _service.fetchSessions();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emploi du temps')),
      body: FutureBuilder<List<Session>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger l’emploi du temps.'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sessions = _service.fetchSessions();
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return _buildSchedule(snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildSchedule(List<Session> sessions) {
    final days = _showWeek
        ? sessions.map((session) => session.day).toSet()
        : {_demoDay};
    final visibleSessions = sessions.where(
      (session) => days.contains(session.day),
    );

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Jour')),
              ButtonSegment(value: true, label: Text('Semaine')),
            ],
            selected: {_showWeek},
            onSelectionChanged: (selection) {
              setState(() {
                _showWeek = selection.single;
              });
            },
          ),
        ),
        if (visibleSessions.isEmpty) ...[
          const SizedBox(height: AppDimensions.space24),
          const Text('Aucun cours prévu.', style: AppTextStyles.body),
        ],
        for (final day in days.where(
          (day) => visibleSessions.any((session) => session.day == day),
        )) ...[
          const SizedBox(height: AppDimensions.space24),
          Text(day, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimensions.space8),
          for (final session in visibleSessions.where(
            (item) => item.day == day,
          ))
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule, color: AppColors.slate),
                title: Text(session.course, style: AppTextStyles.body),
                subtitle: Text(
                  '${session.startTime} – ${session.endTime}\n${session.room}',
                  style: AppTextStyles.compactBody,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSessionDetails(session),
              ),
            ),
        ],
      ],
    );
  }

  void _showSessionDetails(Session session) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(session.course),
        content: Text(
          '${session.day}\n'
          '${session.startTime} – ${session.endTime}\n'
          '${session.room}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
