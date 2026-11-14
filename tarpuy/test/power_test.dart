import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tarpuy/services/nasa/power.dart';
import '../server/server.dart' as backend;

Map<String, dynamic> fixture() => {
  'header': {'fill_value': -999},
  'properties': {
    'parameter': {
      'T2M': {'20250101': 12.5, '20250102': -999},
      'ALLSKY_SFC_SW_DWN': {'20250101': 5.2},
    },
  },
  'parameters': {
    'T2M': {'units': 'C'},
    'ALLSKY_SFC_SW_DWN': {'units': 'kW-hr/m^2/day'},
  },
};
final query = {
  'latitude': '-13.5',
  'longitude': '-71.9',
  'start': '20250101',
  'end': '20250102',
};
void main() {
  test(
    'Archivos estáticos rechazan separadores codificados y rutas externas',
    () {
      expect(
        backend.unsafeStaticPath(Uri.parse('/%2e%2e%2fREADME.md')),
        isTrue,
      );
      expect(backend.unsafeStaticPath(Uri.parse('/C%3A/test')), isTrue);
      expect(backend.unsafeStaticPath(Uri.parse('/%5c%5ctest')), isTrue);
      expect(
        backend.unsafeStaticPath(
          Uri.parse('/assets/fonts/MaterialIcons-Regular.otf'),
        ),
        isFalse,
      );
    },
  );
  test('Conserva faltantes, unidades oficiales y procedencia', () {
    final result = PowerService.normalize(
      fixture(),
      query,
      Uri.parse('https://example.test'),
    );
    expect(result.measurements.where((m) => m.value == null), hasLength(1));
    expect(result.latest('T2M')!.observationDate, DateTime.utc(2025, 1, 1));
    expect(result.latest('ALLSKY_SFC_SW_DWN')!.unit, 'kW-hr/m^2/day');
    expect(result.latest('T2M')!.type, 'estimado');
    expect(result.latest('SMAP'), isNull);
  });
  test('Cache y solicitudes simultáneas realizan una sola llamada', () async {
    var count = 0;
    final service = PowerService(
      client: MockClient((request) async {
        count++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(jsonEncode(fixture()), 200);
      }),
    );
    final a = service.fetch(
      -13.5,
      -71.9,
      DateTime.utc(2025, 1, 1),
      DateTime.utc(2025, 1, 2),
    );
    final b = service.fetch(
      -13.5,
      -71.9,
      DateTime.utc(2025, 1, 1),
      DateTime.utc(2025, 1, 2),
    );
    await Future.wait([a, b]);
    await service.fetch(
      -13.5,
      -71.9,
      DateTime.utc(2025, 1, 1),
      DateTime.utc(2025, 1, 2),
    );
    expect(count, 1);
    service.dispose();
  });
  test('Un fallo libera la solicitud para poder reintentar', () async {
    var count = 0;
    final service = PowerService(
      client: MockClient(
        (_) async => ++count == 1
            ? http.Response('unavailable', 503)
            : http.Response(jsonEncode(fixture()), 200),
      ),
    );
    await expectLater(
      service.fetch(-13.5, -71.9, DateTime.utc(2025), DateTime.utc(2025, 1, 2)),
      throwsException,
    );
    expect(
      await service.fetch(
        -13.5,
        -71.9,
        DateTime.utc(2025),
        DateTime.utc(2025, 1, 2),
      ),
      isA<PowerResult>(),
    );
    service.dispose();
  });
  test('Rechaza coordenadas, fechas futuras y rangos excesivos', () {
    final service = PowerService();
    expect(
      () => service.fetch(double.nan, 0, DateTime(2025), DateTime(2025)),
      throwsArgumentError,
    );
    expect(
      () => service.fetch(91, 0, DateTime(2025), DateTime(2025)),
      throwsArgumentError,
    );
    expect(
      () => service.fetch(0, 0, DateTime(2024), DateTime(2026)),
      throwsArgumentError,
    );
    expect(
      () => service.fetch(0, 0, DateTime(2099), DateTime(2099)),
      throwsArgumentError,
    );
    service.dispose();
  });
  test('Backend consulta solo endpoint NASA fijo y valida fechas reales', () {
    final uri = backend.powerUri({
      ...query,
      'url': 'https://untrusted.test',
      'parameters': 'other',
    });
    expect(uri.host, 'power.larc.nasa.gov');
    expect(uri.queryParameters['parameters'], powerParameters.join(','));
    expect(uri.queryParameters['time-standard'], 'UTC');
    expect(
      () => backend.powerUri({...query, 'start': '20250231'}),
      throwsFormatException,
    );
    expect(
      () => backend.powerUri({...query, 'latitude': 'NaN'}),
      throwsFormatException,
    );
  });
  test(
    'Backend cachea respuesta normalizada e identifica fecha real de consulta',
    () async {
      var count = 0;
      final client = MockClient((_) async {
        count++;
        return http.Response(jsonEncode(fixture()), 200);
      });
      final proxy = backend.PowerProxy(client);
      final result = jsonDecode(await proxy.fetch(query));
      await proxy.fetch(query);
      expect(count, 1);
      expect(DateTime.tryParse(result['_tarpuyFetchedAt']), isNotNull);
      client.close();
    },
  );
}
