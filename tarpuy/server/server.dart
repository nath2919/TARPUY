import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tarpuy/services/nasa/power.dart';

DateTime parseDay(String? value) {
  if (value == null || !RegExp(r'^\d{8}$').hasMatch(value)) {
    throw const FormatException('Fecha inválida');
  }
  final day = DateTime.utc(
    int.parse(value.substring(0, 4)),
    int.parse(value.substring(4, 6)),
    int.parse(value.substring(6)),
  );
  if ('${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}' !=
      value) {
    throw const FormatException('Fecha inválida');
  }
  return day;
}

Uri powerUri(Map<String, String> query) {
  final lat = double.tryParse(query['latitude'] ?? '');
  final lon = double.tryParse(query['longitude'] ?? '');
  if (lat == null ||
      lon == null ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat.abs() > 90 ||
      lon.abs() > 180) {
    throw const FormatException('Coordenadas inválidas');
  }
  final start = parseDay(query['start']);
  final end = parseDay(query['end']);
  if (start.year < 1981 ||
      start.isAfter(end) ||
      end.difference(start).inDays > 366 ||
      end.isAfter(DateTime.now().toUtc())) {
    throw const FormatException(
      'Periodo inválido: máximo 366 días y sin fechas futuras',
    );
  }
  return Uri.https('power.larc.nasa.gov', '/api/temporal/daily/point', {
    'latitude': '$lat',
    'longitude': '$lon',
    'start': query['start']!,
    'end': query['end']!,
    'parameters': powerParameters.join(','),
    'community': 'AG',
    'format': 'JSON',
    'time-standard': 'UTC',
  });
}

class PowerProxy {
  final http.Client client;
  final _cache = <String, ({DateTime at, String body})>{};
  final _pending = <String, Future<String>>{};
  PowerProxy(this.client);
  Future<String> fetch(Map<String, String> query) {
    final uri = powerUri(query);
    final key = uri.toString();
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().toUtc().difference(cached.at).inHours < 6) {
      return Future.value(cached.body);
    }
    return _pending.putIfAbsent(
      key,
      () => _load(uri)
          .then((body) {
            if (_cache.length >= 128) _cache.remove(_cache.keys.first);
            _cache[key] = (at: DateTime.now().toUtc(), body: body);
            return body;
          })
          .whenComplete(() {
            _pending.remove(key);
          }),
    );
  }

  Future<String> _load(Uri uri) async {
    final response = await client.get(uri).timeout(const Duration(seconds: 55));
    if (response.statusCode != 200) {
      throw HttpException('NASA respondió HTTP ${response.statusCode}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if ((payload['properties'] as Map?)?['parameter'] == null) {
      throw const FormatException('Respuesta NASA incompleta');
    }
    payload['_tarpuyFetchedAt'] = DateTime.now().toUtc().toIso8601String();
    return jsonEncode(payload);
  }
}

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8787;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final client = http.Client();
  final proxy = PowerProxy(client);
  final root = Directory('build/web').absolute;
  stdout.writeln('TARPUY: http://localhost:$port');
  await for (final request in server) {
    unawaited(handle(request, proxy, root));
  }
}

bool unsafeStaticPath(Uri uri) => uri.pathSegments.any(
  (s) =>
      s == '..' ||
      s == '.' ||
      s.contains('/') ||
      s.contains('\\') ||
      s.contains(':') ||
      s.contains('\u0000'),
);

Future<void> handle(
  HttpRequest request,
  PowerProxy proxy,
  Directory root,
) async {
  final response = request.response;
  // Local development only. Production should be same-origin behind HTTPS.
  final origin = request.headers.value('origin');
  if (origin != null) {
    final parsed = Uri.tryParse(origin);
    if (parsed != null && ['localhost', '127.0.0.1'].contains(parsed.host)) {
      response.headers.set('Access-Control-Allow-Origin', origin);
      response.headers.set('Vary', 'Origin');
    }
  }
  try {
    if (request.method == 'OPTIONS') {
      response.statusCode = 204;
      response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    } else if (request.method != 'GET') {
      response.statusCode = 405;
    } else if (request.uri.path == '/api/power') {
      response.headers.contentType = ContentType.json;
      try {
        powerUri(request.uri.queryParameters);
      } on FormatException catch (e) {
        response.statusCode = 400;
        response.write(jsonEncode({'error': e.message}));
        return;
      }
      response.write(await proxy.fetch(request.uri.queryParameters));
    } else if (request.uri.path == '/api/health') {
      response.headers.contentType = ContentType.json;
      response.write('{"service":"TARPUY","status":"ok"}');
    } else {
      final segments = request.uri.pathSegments;
      if (unsafeStaticPath(request.uri)) {
        response.statusCode = 400;
        return;
      }
      final file = File(
        '${root.path}/${segments.isEmpty || request.uri.path == '/' ? 'index.html' : segments.join('/')}',
      );
      if (!await file.exists()) {
        response.statusCode = 404;
        response.write(
          'Recurso no encontrado. Ejecuta flutter build web desde tarpuy.',
        );
      } else {
        final ext = file.path.split('.').last;
        final types = {
          'html': 'text/html',
          'js': 'application/javascript',
          'json': 'application/json',
          'css': 'text/css',
          'png': 'image/png',
          'ico': 'image/x-icon',
          'svg': 'image/svg+xml',
          'wasm': 'application/wasm',
          'woff2': 'font/woff2',
          'ttf': 'font/ttf',
        };
        response.headers.set(
          'Content-Type',
          types[ext] ?? 'application/octet-stream',
        );
        response.headers.set('X-Content-Type-Options', 'nosniff');
        await response.addStream(file.openRead());
      }
    }
  } on TimeoutException {
    response.statusCode = 504;
    response.write('{"error":"NASA no respondió a tiempo"}');
  } catch (_) {
    response.statusCode = 502;
    response.write(
      '{"error":"No se pudieron obtener datos de NASA. Reintenta más tarde."}',
    );
  } finally {
    await response.close();
  }
}
