import 'package:flutter_test/flutter_test.dart';

import 'package:university_life/app.dart';

void main() {
  testWidgets('L\'espace professeur s\'affiche', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Leila.'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
  });
}
