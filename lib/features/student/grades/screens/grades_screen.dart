import 'package:flutter/material.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/student/grades/models/grade_model.dart';
import 'package:university_life/features/student/grades/services/grades_service.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _service = GradesService();
  late Future<List<Grade>> _grades;

  @override
  void initState() {
    super.initState();
    _grades = _service.fetchGrades();
  }

  void _retry() {
    setState(() {
      _grades = _service.fetchGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes notes')),
      body: FutureBuilder<List<Grade>>(
        future: _grades,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Impossible de charger les notes.'),
                    TextButton(
                      onPressed: _retry,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final grades = snapshot.data ?? const <Grade>[];
          if (grades.isEmpty) {
            return const Center(child: Text('Aucune note disponible.'));
          }

          final total = grades.fold<double>(0, (sum, grade) => sum + grade.score);
          final average = total / grades.length;

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.space20),
            children: [
              Text(
                'Moyenne générale · ${_formatScore(average)} / 20',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: AppDimensions.space16),
              for (final grade in grades)
                Card(
                  child: ListTile(
                    title: Text(grade.module, style: AppTextStyles.body),
                    trailing: Text(
                      '${_formatScore(grade.score)} / 20',
                      style: AppTextStyles.compactBody,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatScore(double score) {
    return score.toStringAsFixed(1).replaceFirst('.', ',');
  }
}