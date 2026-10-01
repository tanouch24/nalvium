import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nalvium_app/main.dart';
import 'package:nalvium_app/api_client.dart';
import 'package:nalvium_app/equipment_screens.dart';
import 'package:nalvium_app/history_store.dart';
import 'package:nalvium_app/repair_network_screens.dart';
import 'package:nalvium_app/materials_screens.dart';
import 'package:nalvium_app/support_screens.dart';

void main() {
  testWidgets('onboarding shows primary action', (tester) async {
    await tester.pumpWidget(const NalviumApp());
    expect(find.text('Continuer'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('onboarding reaches real home capture entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Qu’est-ce qui se passe\nchez vous ?'), findsOneWidget);
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir une photo'), findsOneWidget);
  });

  testWidgets('home presents privacy safety reminder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.byTooltip('Historique'), findsOneWidget);
    expect(find.text('NALVIUM').first, findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('En cas de gaz'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('En cas de gaz'), findsOneWidget);
  });

  testWidgets('equipment confirmation keeps identification editable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentConfirmationScreen(
          api: const ApiClient(),
          history: HistoryStore(),
          identification: {
            'object_type': 'equipment',
            'category': 'washing_machine',
            'suggested_name': 'Machine à laver',
            'brand': {'value': 'Samsung'},
            'needs_nameplate_photo': true,
          },
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Ajouter à Ma Maison'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ajouter à Ma Maison'), findsOneWidget);
    expect(find.text('Machine à laver'), findsOneWidget);
  });

  testWidgets('equipment detail exposes documents warranty and maintenance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentDetailScreen(
          api: const ApiClient(),
          history: HistoryStore(),
          equipment: {
            'id': 'equipment-test',
            'display_name': 'Machine à laver Samsung',
            'category': 'washing_machine',
            'brand': 'Samsung',
            'model': 'WW90',
            'room': 'Buanderie',
            'documents': [],
            'warranties': [],
            'maintenance': [],
            'repairs': [],
          },
        ),
      ),
    );
    expect(find.text('Documents'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Garantie'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Garantie'), findsOneWidget);
    expect(find.text('Entretien'), findsOneWidget);
    expect(find.text('Aucun entretien enregistré.'), findsOneWidget);
  });

  testWidgets('repair request detail keeps availability honest', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RepairRequestDetailScreen(
          request: {
            'description': 'Fuite sous évier',
            'status': 'REQUESTED',
            'postal_code': '75011',
            'desired_time_window': '',
          },
        ),
      ),
    );
    expect(find.text('Fuite sous évier'), findsOneWidget);
    expect(find.textContaining('Aucun artisan'), findsOneWidget);
  });

  testWidgets('required material blocks until mandatory item is owned', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RequiredItemsScreen(
      api: const ApiClient(),
      items: const [{'type': 'TOOL', 'name': 'Tournevis', 'required': true}],
      onContinue: _noop,
    )));
    expect(find.text('Tournevis'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'J’ai le matériel — Continuer'));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'J’ai le matériel — Continuer')).onPressed, isNotNull);
  });

  testWidgets('support page stays disabled without a payment provider', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('contributions'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Soutenir Nalvium'), findsNothing);
  });
}

void _noop() {}
