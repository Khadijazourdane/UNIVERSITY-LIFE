import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/app.dart';
import 'package:university_life/core/theme/app_theme.dart';

void main() {
  testWidgets('UniversityLifeApp starts with the official theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UniversityLifeApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'University Life');
    expect(materialApp.theme, same(AppTheme.light));
    expect(materialApp.debugShowCheckedModeBanner, isFalse);
  });
}
