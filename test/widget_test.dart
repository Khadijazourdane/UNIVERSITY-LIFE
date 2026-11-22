import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/main.dart';

void main() {
  testWidgets('L’application ouvre le tableau de bord étudiant', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Bonjour, Lina !'), findsOneWidget);
    expect(find.text('Prochain cours'), findsOneWidget);
    expect(find.text('Annonces'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Absences'), 100);
    expect(find.text('Absences'), findsOneWidget);
  });
}
