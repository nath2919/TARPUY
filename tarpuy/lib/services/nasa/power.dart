import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models.dart';

const powerParameters = [
  'T2M',
  'T2M_MAX',
  'T2M_MIN',
  'PRECTOTCORR',
  'RH2M',
  'ALLSKY_SFC_SW_DWN',
];
const powerSource =
    'https://power.larc.nasa.gov/docs/services/api/temporal/daily/';

class Measurement {
  final String variable,
      unit,
      datasetId,
      provider,
      spatialResolution,
      temporalResolution,
      qualityFlag,
      sourceUrl,
      type;
  final double? value;
  final DateTime observationDate, fetchedAt;
  final double latitude, longitude;
  const Measurement({
    required this.variable,
    required this.unit,
    required this.value,
    required this.observationDate,
    required this.fetchedAt,
    required this.latitude,
    required this.longitude,
    this.datasetId = 'NASA_POWER_DAILY',
    this.provider = 'NASA POWER',
    this.spatialResolution =
        'Regional; depende de la variable y del producto de origen',
    this.temporalResolution = 'Diaria · UTC',
    required this.qualityFlag,
    this.sourceUrl = powerSource,
    this.type = 'estimado',
  });
}

class PowerResult {
  final List<Measurement> measurements;
  final DateTime fetchedAt;
  final Uri request;
  const PowerResult(this.measurements, this.fetchedAt, this.request);
  Measurement? latest(String variable) {
    final rows =
        measurements
            .where((m) => m.variable == variable && m.value != null)
            .toList()
          ..sort((a, b) => b.observationDate.compareTo(a.observationDate));
    return rows.isEmpty ? null : rows.first;
  }
}

class PowerService {
  final http.Client client;
  final String proxy;
  final Map<String, PowerResult> _cache = {};
  final Map<String, Future<PowerResult>> _pending = {};
  PowerService({
    http.Client? client,
    this.proxy = const String.fromEnvironment(
      'POWER_PROXY',
      defaultValue: '/api/power',
    ),
  }) : client = client ?? http.Client();
  Future<PowerResult> fetch(
    double latitude,
    double longitude,
    DateTime start,
    DateTime end,
  ) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Coordenadas inválidas');
    }
    if (start.isAfter(end) ||
        end.difference(start).inDays > 366 ||
        start.year < 1981 ||
        end.isAfter(DateTime.now().toUtc())) {
      throw ArgumentError(
        'Periodo inválido: máximo 366 días y sin fechas futuras',
      );
    }
    final query = {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'start': apiDate(start),
      'end': apiDate(end),
    };
    final key = query.toString();
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().toUtc().difference(cached.fetchedAt).inHours < 6) {
      return Future.value(cached);
    }
    return _pending.putIfAbsent(
      key,
      () => _load(query)
          .then((result) {
            _cache[key] = result;
            return result;
          })
          .whenComplete(() {
            _pending.remove(key);
          }),
    );
  }

  Future<PowerResult> _load(Map<String, String> query) async {
    final uri = Uri.parse(proxy).replace(queryParameters: query);
    final response = await client.get(uri).timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw Exception(
        'NASA POWER no disponible (HTTP ${response.statusCode}). Reintenta más tarde.',
      );
    }
    return normalize(
      jsonDecode(response.body) as Map<String, dynamic>,
      query,
      uri,
    );
  }

  static PowerResult normalize(
    Map<String, dynamic> json,
    Map<String, String> query,
    Uri request,
  ) {
    final params = (json['properties'] as Map?)?['parameter'] as Map?;
    if (params == null) {
      throw const FormatException('Respuesta NASA sin parámetros');
    }
    final units = json['parameters'] as Map? ?? {};
    final fill =
        ((json['header'] as Map?)?['fill_value'] as num?)?.toDouble() ?? -999;
    final fetched =
        DateTime.tryParse(json['_tarpuyFetchedAt'] as String? ?? '') ??
        DateTime.now().toUtc();
    final rows = <Measurement>[];
    for (final variable in powerParameters) {
      final series = params[variable] as Map? ?? {};
      for (final entry in series.entries) {
        final day = entry.key.toString();
        if (!RegExp(r'^\d{8}$').hasMatch(day)) continue;
        final raw = (entry.value as num?)?.toDouble();
        final valid = raw != null && raw.isFinite && raw != fill && raw != -999;
        rows.add(
          Measurement(
            variable: variable,
            unit:
                ((units[variable] as Map?)?['units'] ??
                        'Sin unidad documentada')
                    .toString(),
            value: valid ? raw : null,
            observationDate: DateTime.utc(
              int.parse(day.substring(0, 4)),
              int.parse(day.substring(4, 6)),
              int.parse(day.substring(6)),
            ),
            fetchedAt: fetched,
            latitude: double.parse(query['latitude']!),
            longitude: double.parse(query['longitude']!),
            qualityFlag: valid ? 'AVAILABLE' : 'MISSING',
          ),
        );
      }
    }
    return PowerResult(rows, fetched, request);
  }

  void dispose() => client.close();
}
