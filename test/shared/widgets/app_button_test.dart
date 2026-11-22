import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/shared/widgets/app_button.dart';

Future<void> _pumpButton(WidgetTester tester, Widget button) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  testWidgets('renders the primary action and calls its callback', (
    WidgetTester tester,
  ) async {
    var pressed = false;
    await _pumpButton(
      tester,
      AppButton(label: 'Continuer', onPressed: () => pressed = true),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height, 50);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(pressed, isTrue);
  });

  testWidgets('renders the secondary variant with an outlined button', (
    WidgetTester tester,
  ) async {
    await _pumpButton(
      tester,
      AppButton(
        label: 'Annuler',
        onPressed: () {},
        variant: AppButtonVariant.secondary,
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('disables the action and shows an accessible loading indicator', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpButton(
        tester,
        AppButton(label: 'Connexion', onPressed: () {}, isLoading: true),
      );

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Chargement en cours')),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('keeps a disabled action inactive', (WidgetTester tester) async {
    await _pumpButton(
      tester,
      const AppButton(label: 'Envoyer', onPressed: null),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
