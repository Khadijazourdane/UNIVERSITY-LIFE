import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/shared/widgets/app_text_field.dart';

void main() {
  testWidgets('shows its visible label, hint, and accessible field label', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppTextField(
              label: 'Adresse universitaire',
              hintText: 'prenom.nom@edu.uiz.ac.ma',
            ),
          ),
        ),
      );

      expect(find.text('Adresse universitaire'), findsOneWidget);
      expect(find.text('prenom.nom@edu.uiz.ac.ma'), findsOneWidget);
      expect(find.bySemanticsLabel('Adresse universitaire'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('forwards the validator to TextFormField', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: const AppTextField(
              label: 'Mot de passe',
              validator: _requiredValidator,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
  });

  testWidgets('forwards password visibility and the suffix control', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppTextField(
            label: 'Mot de passe',
            obscureText: true,
            suffixIcon: Icon(Icons.visibility),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}

String? _requiredValidator(String? value) {
  if (value == null || value.isEmpty) return 'Ce champ est obligatoire.';
  return null;
}
