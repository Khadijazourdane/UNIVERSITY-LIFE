import 'package:flutter/material.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/student/absences/models/absence_model.dart';
import 'package:university_life/features/student/absences/services/absences_service.dart';

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});

  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  final _service = AbsencesService();
  late Future<List<Absence>> _absences;

  @override
  void initState() {
    super.initState();
    _absences = _service.fetchAbsences();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _absences = _service.fetchAbsences();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes absences')),
      body: FutureBuilder<List<Absence>>(
        future: _absences,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les absences.'),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final absences = snapshot.data ?? const <Absence>[];
          if (absences.isEmpty) {
            return const Center(child: Text('Aucune absence ce semestre.'));
          }

          final summary = absences.length == 1
              ? '1 absence ce semestre'
              : '${absences.length} absences ce semestre';

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.space20),
            children: [
              Text(summary, style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppDimensions.space16),
              for (final absence in absences)
                Card(
                  child: ListTile(
                    title: Text(absence.module, style: AppTextStyles.body),
                    subtitle: Text(
                      '${absence.date}\n'
                      '${absence.isJustified ? 'Justifiée' : 'Non justifiée'}',
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
}