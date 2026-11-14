import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarpuy/main.dart';
import 'package:tarpuy/data/app_state.dart';
import 'package:tarpuy/ui/plot_screen.dart';
import 'package:tarpuy/ui/modules.dart';
import 'package:tarpuy/ui/dashboard.dart';
import 'package:tarpuy/data/models.dart';
import 'package:tarpuy/services/nasa/power.dart';
import 'package:tarpuy/data/storage.dart';

void main() {
  testWidgets(
    'Guardar parcela persiste los campos y cancelar respaldo conserva la edición',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PlotScreen(state: state)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      for (final entry in {
        0: 'Mi chacra',
        1: 'Cusco',
        2: 'Cusco',
        3: 'San Jerónimo',
        4: '-13.5',
        5: '-71.9',
        6: '1.5',
        7: '3200',
      }.entries) {
        await tester.enterText(fields.at(entry.key), entry.value);
      }
      final save = find.text('Guardar mi parcela');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(state.plot!.name, 'Mi chacra');
      expect(state.plot!.area, 1.5);
      expect(state.plot!.ph, isNull);
      expect(readLocal('plot'), contains('Mi chacra'));
      await tester.enterText(fields.first, 'Nombre todavía sin guardar');
      final restore = find.text('Restaurar respaldo');
      await tester.ensureVisible(restore);
      await tester.tap(restore);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(fields.first).controller!.text,
        'Nombre todavía sin guardar',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      // Reset isolated in-memory storage for the remaining widget cases.
    removeLocal('plot');
    },
  );
  testWidgets('Datos cargados, agenda y gráficos se adaptan a móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState();
    state.plot = Plot(
      name: 'Parcela de prueba',
      department: 'Cusco',
      province: 'Cusco',
      district: 'Cusco',
      latitude: -13.5,
      longitude: -71.9,
      area: 2,
      altitude: 3200,
      updatedAt: DateTime.utc(2025),
    );
    state.tasks.add(
      FarmTask('Analizar la fertilidad del suelo', DateTime.now()),
    );
    state.weather = PowerService.normalize(
      {
        'properties': {
          'parameter': {
            'T2M': {'20250101': 10, '20250102': 12},
            'ALLSKY_SFC_SW_DWN': {'20250101': 14.5},
          },
        },
        'parameters': {
          'T2M': {'units': 'C'},
          'ALLSKY_SFC_SW_DWN': {'units': 'MJ/m^2/day'},
        },
      },
      {'latitude': '-13.5', 'longitude': '-71.9'},
      Uri.parse('https://example.test'),
    );
    for (final screen in [
      Dashboard(state: state, navigate: (_) {}),
      NasaScreen(state: state),
      CalendarScreen(state: state),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: screen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} con datos',
      );
    }
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets('Dashboard, menú y todos los módulos funcionan en escritorio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TarpuyApp());
    await tester.pumpAndSettle();
    expect(find.text('Cada siembra, un nuevo futuro.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final page in pages.skip(1)) {
      final item = find.widgetWithText(ListTile, page);
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(find.text(page), findsWidgets);
      expect(tester.takeException(), isNull, reason: page);
    }
  });
  testWidgets('Vistas móviles sin desbordamientos y formulario valida vacíos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TarpuyApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final state = AppState();
    addTearDown(state.dispose);
    for (final page in [
      PlotScreen(state: state),
      CalendarScreen(state: state),
      RotationScreen(state: state),
      RegenerationScreen(state: state),
      NasaScreen(state: state),
      EconomyScreen(state: state),
      AstronomyScreen(state: state),
      AssistantScreen(state: state),
      ImpactScreen(state: state),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
      if (page is PlotScreen) {
        final save = find.text('Guardar mi parcela');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(state.plot, isNull);
        expect(find.text('Completa este campo'), findsWidgets);
      }
    }
  });
}
