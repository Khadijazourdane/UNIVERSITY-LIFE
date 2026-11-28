import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/app.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/features/auth/screens/forgot_password_screen.dart';
import 'package:university_life/features/auth/screens/login_screen.dart';

void _setPhoneViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _pumpForgotPasswordScreen(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
}) async {
  _setPhoneViewport(tester, Size(width, height));
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const ForgotPasswordScreen()),
  );
}

Future<void> _submitForm(WidgetTester tester) async {
  final submitButton = find.text('Envoyer le lien');
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the forgot-password content from the mockup', (
    WidgetTester tester,
  ) async {
    await _pumpForgotPasswordScreen(tester);

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Mot de passe oublié'), findsOneWidget);
    expect(find.text('Retrouver votre accès'), findsOneWidget);
    expect(
      find.text(
        'La récupération en ligne est en cours de préparation. '
        'Pour retrouver votre accès, contactez la scolarité.',
      ),
      findsOneWidget,
    );
    expect(find.text('Adresse universitaire'), findsOneWidget);
    expect(find.text('prenom.nom@edu.uiz.ac.ma'), findsOneWidget);
    expect(find.text('Envoyer le lien'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(Form), findsOneWidget);
  });

  testWidgets('requires an email address', (WidgetTester tester) async {
    await _pumpForgotPasswordScreen(tester);
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir votre adresse universitaire.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a malformed email address', (WidgetTester tester) async {
    await _pumpForgotPasswordScreen(tester);
    await tester.enterText(
      find.byType(TextFormField),
      'prenom.nom.edu.uiz.ac.ma',
    );
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir une adresse email valide.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects an address from another domain', (
    WidgetTester tester,
  ) async {
    await _pumpForgotPasswordScreen(tester);
    await tester.enterText(
      find.byType(TextFormField),
      'prenom.nom@example.com',
    );
    await _submitForm(tester);

    expect(
      find.text('Utilisez une adresse se terminant par @edu.uiz.ac.ma.'),
      findsOneWidget,
    );
  });

  testWidgets('accepts a university email without simulating a send', (
    WidgetTester tester,
  ) async {
    await _pumpForgotPasswordScreen(tester);
    await tester.enterText(
      find.byType(TextFormField),
      'prenom.nom@edu.uiz.ac.ma',
    );
    await _submitForm(tester);

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
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
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Lien envoyé'), findsNothing);
    expect(find.text('Votre lien a été envoyé.'), findsNothing);
    expect(
      find.text('Aucun lien envoyé. Contactez la scolarité.'),
      findsOneWidget,
    );
    expect(find.text('Envoyer le lien'), findsOneWidget);
  });

  testWidgets('opens from LoginScreen and returns to it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UniversityLifeApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Retour à la connexion'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ForgotPasswordScreen), findsNothing);
  });

  testWidgets('fits a compact phone when validation errors are shown', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpForgotPasswordScreen(tester, width: 320, height: 568);
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir votre adresse universitaire.'),
      findsOneWidget,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'The screen and its validation message must fit at 320 px.',
    );
  });
}
