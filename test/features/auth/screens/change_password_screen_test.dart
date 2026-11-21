import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/features/auth/screens/change_password_screen.dart';

void _setPhoneViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _pumpChangePasswordScreen(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
}) async {
  _setPhoneViewport(tester, Size(width, height));
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const ChangePasswordScreen()),
  );
}

Future<void> _enterPasswords(
  WidgetTester tester, {
  required String current,
  required String next,
  required String confirmation,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('current-password-field')),
    current,
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-password-field')),
    next,
  );
  await tester.enterText(
    find.byKey(const ValueKey('confirmation-password-field')),
    confirmation,
  );
}

Future<void> _submitForm(WidgetTester tester) async {
  final submitButton = find.byType(FilledButton);
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, String fieldKey) {
  final field = find.byKey(ValueKey(fieldKey));
  final editableText = tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
  return editableText.controller.text;
}

Future<void> _verifyVisibilityToggle(
  WidgetTester tester, {
  required String fieldKey,
  required String visibilityKey,
  required String password,
}) async {
  final field = find.byKey(ValueKey(fieldKey));
  final textField = find.descendant(
    of: field,
    matching: find.byType(TextField),
  );
  final visibilityButton = find.byKey(ValueKey(visibilityKey));

  expect(tester.widget<TextField>(textField).obscureText, isTrue);
  await tester.ensureVisible(visibilityButton);
  await tester.tap(visibilityButton);
  await tester.pump();

  expect(tester.widget<TextField>(textField).obscureText, isFalse);
  expect(_fieldText(tester, fieldKey) == password, isTrue);

  await tester.tap(visibilityButton);
  await tester.pump();

  expect(tester.widget<TextField>(textField).obscureText, isTrue);
  expect(_fieldText(tester, fieldKey) == password, isTrue);
}

void main() {
  testWidgets('shows the three password fields and submit button', (
    WidgetTester tester,
  ) async {
    await _pumpChangePasswordScreen(tester);

    expect(find.text('Changer le mot de passe'), findsNWidgets(2));
    expect(find.text('Mot de passe actuel'), findsOneWidget);
    expect(find.text('Nouveau mot de passe'), findsOneWidget);
    expect(find.text('Confirmer le nouveau mot de passe'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(Form), findsOneWidget);
  });

  testWidgets('requires all three fields', (WidgetTester tester) async {
    await _pumpChangePasswordScreen(tester);
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir votre mot de passe actuel.'),
      findsOneWidget,
    );
    expect(
      find.text('Veuillez saisir un nouveau mot de passe.'),
      findsOneWidget,
    );
    expect(
      find.text('Veuillez confirmer le nouveau mot de passe.'),
      findsOneWidget,
    );
  });

  testWidgets('requires at least eight characters for the new password', (
    WidgetTester tester,
  ) async {
    await _pumpChangePasswordScreen(tester);
    await _enterPasswords(
      tester,
      current: 'CurrentPassword1',
      next: 'short7',
      confirmation: 'short7',
    );
    await _submitForm(tester);

    expect(
      find.text('Le nouveau mot de passe doit contenir au moins 8 caractères.'),
      findsOneWidget,
    );
  });

  testWidgets('requires a new password different from the current one', (
    WidgetTester tester,
  ) async {
    await _pumpChangePasswordScreen(tester);
    await _enterPasswords(
      tester,
      current: 'SamePassword1',
      next: 'SamePassword1',
      confirmation: 'SamePassword1',
    );
    await _submitForm(tester);

    expect(
      find.text(
        'Le nouveau mot de passe doit être différent du mot de passe actuel.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('requires an exact password confirmation match', (
    WidgetTester tester,
  ) async {
    await _pumpChangePasswordScreen(tester);
    await _enterPasswords(
      tester,
      current: 'CurrentPassword1',
      next: 'NewPassword123',
      confirmation: 'NewPassword124',
    );
    await _submitForm(tester);

    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );
  });

  testWidgets('valid values do not simulate a password change', (
    WidgetTester tester,
  ) async {
    await _pumpChangePasswordScreen(tester);
    await _enterPasswords(
      tester,
      current: 'CurrentPassword1',
      next: 'NewPassword123',
      confirmation: 'NewPassword123',
    );
    await _submitForm(tester);

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Mot de passe modifié'), findsNothing);
    expect(
      _fieldText(tester, 'current-password-field') == 'CurrentPassword1',
      isTrue,
    );
    expect(
      _fieldText(tester, 'new-password-field') == 'NewPassword123',
      isTrue,
    );
    expect(
      _fieldText(tester, 'confirmation-password-field') == 'NewPassword123',
      isTrue,
    );
    expect(
      find.text('Le nouveau mot de passe doit contenir au moins 8 caractères.'),
      findsNothing,
    );
    expect(
      find.text(
        'Le nouveau mot de passe doit être différent du mot de passe actuel.',
      ),
      findsNothing,
    );
    expect(find.text('Les mots de passe ne correspondent pas.'), findsNothing);
  });

  testWidgets('shows and hides each password without losing its text', (
    WidgetTester tester,
  ) async {
    await _pumpChangePasswordScreen(tester);
    await _enterPasswords(
      tester,
      current: 'CurrentPassword1',
      next: 'NewPassword123',
      confirmation: 'NewPassword123',
    );

    await _verifyVisibilityToggle(
      tester,
      fieldKey: 'current-password-field',
      visibilityKey: 'current-password-visibility',
      password: 'CurrentPassword1',
    );
    await _verifyVisibilityToggle(
      tester,
      fieldKey: 'new-password-field',
      visibilityKey: 'new-password-visibility',
      password: 'NewPassword123',
    );
    await _verifyVisibilityToggle(
      tester,
      fieldKey: 'confirmation-password-field',
      visibilityKey: 'confirmation-password-visibility',
      password: 'NewPassword123',
    );
  });

  testWidgets('returns to the previous screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
              child: const Text('Page précédente de test'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Page précédente de test'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Retour à l’écran précédent'));
    await tester.pumpAndSettle();

    expect(find.text('Page précédente de test'), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsNothing);
  });

  testWidgets('fits a compact phone when validation errors are shown', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpChangePasswordScreen(tester, width: 320, height: 568);
    await _submitForm(tester);

    expect(
      find.text('Veuillez saisir votre mot de passe actuel.'),
      findsOneWidget,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'Validation errors must fit at 320 px.',
    );
  });
}
