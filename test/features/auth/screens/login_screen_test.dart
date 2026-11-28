import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/app.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/features/auth/screens/login_screen.dart';

void _setPhoneViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _pumpLoginScreen(WidgetTester tester, {double width = 390}) async {
  _setPhoneViewport(tester, Size(width, 844));
  await tester.pumpWidget(const UniversityLifeApp());
}

Future<void> _submitForm(WidgetTester tester) async {
  final submitButton = find.text('Se connecter →');
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the login content and both fields', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester);

    expect(find.text('UNIVERSITY LIFE'), findsOneWidget);
    expect(find.text('Votre campus, à portée de main.'), findsOneWidget);
    expect(find.text('Étudier. Enseigner. Organiser.'), findsOneWidget);
    expect(find.text('Bienvenue.'), findsOneWidget);
    expect(find.text('Adresse universitaire'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Se connecter →'), findsOneWidget);
    expect(
      find.text('Besoin d’aide ? Contactez la scolarité.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(Form), findsOneWidget);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(2));
    expect(fields.first.decoration?.hintText, 'prenom.nom@edu.uiz.ac.ma');
    expect(fields.last.obscureText, isTrue);
    final passwordInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).at(1),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordInput.controller.text, isEmpty);
  });

  testWidgets('requires a university email', (WidgetTester tester) async {
    await _pumpLoginScreen(tester);
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir votre adresse universitaire.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a malformed email address', (WidgetTester tester) async {
    await _pumpLoginScreen(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'prenom.nom.edu.uiz.ac.ma',
    );
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir une adresse email valide.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects an email from another domain', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'prenom.nom@example.com',
    );
    await _submitForm(tester);

    expect(
      find.text('Utilisez une adresse se terminant par @edu.uiz.ac.ma.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a domain that only resembles the official domain', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'prenom.nom@edu.uiz.ac.ma.example.com',
    );
    await _submitForm(tester);

    expect(
      find.text('Utilisez une adresse se terminant par @edu.uiz.ac.ma.'),
      findsOneWidget,
    );
  });

  testWidgets('requires a password but imposes no minimum length', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'prenom.nom@edu.uiz.ac.ma',
    );
    await _submitForm(tester);

    expect(find.text('Veuillez saisir votre mot de passe.'), findsOneWidget);
  });

  testWidgets('accepts the official domain without simulating login', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'prenom.nom@edu.uiz.ac.ma');
    await tester.enterText(fields.at(1), 'x');
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir votre adresse universitaire.'),
      findsNothing,
    );
    expect(
      find.text('Veuillez saisir une adresse email valide.'),
      findsNothing,
    );
    expect(
      find.text('Utilisez une adresse se terminant par @edu.uiz.ac.ma.'),
      findsNothing,
    );
    expect(find.text('Veuillez saisir votre mot de passe.'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Bienvenue.'), findsOneWidget);
  });

  testWidgets('shows and hides the password without losing its text', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpLoginScreen(tester);

      final passwordFormField = find.byType(TextFormField).at(1);
      final passwordTextField = find.byType(TextField).at(1);
      await tester.ensureVisible(passwordTextField);
      await tester.enterText(passwordFormField, 'Campus123');
      expect(tester.widget<TextField>(passwordTextField).obscureText, isTrue);

      final showPassword = find.text('Voir');
      expect(find.bySemanticsLabel('Afficher le mot de passe'), findsOneWidget);
      await tester.ensureVisible(showPassword);
      await tester.tap(showPassword);
      await tester.pump();

      expect(tester.widget<TextField>(passwordTextField).obscureText, isFalse);
      expect(find.text('Masquer'), findsOneWidget);
      expect(find.bySemanticsLabel('Masquer le mot de passe'), findsOneWidget);
      var editableText = tester.widget<EditableText>(
        find.descendant(
          of: passwordFormField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.controller.text, 'Campus123');

      await tester.ensureVisible(find.text('Masquer'));
      await tester.tap(find.text('Masquer'));
      await tester.pump();

      expect(tester.widget<TextField>(passwordTextField).obscureText, isTrue);
      editableText = tester.widget<EditableText>(
        find.descendant(
          of: passwordFormField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.controller.text, 'Campus123');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('uses the official theme and starts on LoginScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UniversityLifeApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme, same(AppTheme.light));
  });

  testWidgets('connect button does not simulate authentication', (
    WidgetTester tester,
  ) async {
    await _pumpLoginScreen(tester);

    final button = find.text('Se connecter →');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Bienvenue.'), findsOneWidget);
  });

  testWidgets('fits reference and compact phone widths without overflow', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final width in [390.0, 320.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(const UniversityLifeApp());
      await _submitForm(tester);

      expect(
        find.text('Veuillez saisir votre adresse universitaire.'),
        findsOneWidget,
      );
      expect(find.text('Veuillez saisir votre mot de passe.'), findsOneWidget);

      expect(
        tester.takeException(),
        isNull,
        reason: 'Validation errors must fit at ${width.toInt()} px.',
      );
    }
  });

  testWidgets('exposes descriptive semantics for fields and password toggle', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const UniversityLifeApp());

      expect(find.bySemanticsLabel('Adresse universitaire'), findsOneWidget);
      expect(find.bySemanticsLabel('Mot de passe'), findsOneWidget);
      expect(find.bySemanticsLabel('Afficher le mot de passe'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
