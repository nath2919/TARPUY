// Optional real-network check. Not part of the offline unit/widget suite.
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tarpuy/services/nasa/power.dart';
import '../server/server.dart';

Future<void> main() async {
  final client = http.Client();
  try {
    final proxy = PowerProxy(client);
    final query = {
      'latitude': '-13.519',
      'longitude': '-71.978',
      'start': '20250101',
      'end': '20250103',
    };
    final response =
        jsonDecode(await proxy.fetch(query)) as Map<String, dynamic>;
    final result = PowerService.normalize(response, query, powerUri(query));
    final temp = result.latest('T2M');
    final radiation = result.latest('ALLSKY_SFC_SW_DWN');
    if (temp == null || radiation == null) {
      throw StateError(
        'No hay observaciones válidas para el periodo de verificación',
      );
    }
    stdout.writeln(
      jsonEncode({
        'provider': temp.provider,
        'observationDate': temp.observationDate.toIso8601String(),
        'temperature': temp.value,
        'temperatureUnit': temp.unit,
        'radiation': radiation.value,
        'radiationUnit': radiation.unit,
        'fetchedAt': temp.fetchedAt.toIso8601String(),
        'validMeasurements': result.measurements
            .where((m) => m.value != null)
            .length,
      }),
    );
  } finally {
    client.close();
  }
}
