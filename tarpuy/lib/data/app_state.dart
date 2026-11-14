import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'storage.dart';
import '../services/nasa/power.dart';

class FarmTask {
  final String name;
  final DateTime date;
  bool done;
  FarmTask(this.name, this.date, {this.done = false});
  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date.toIso8601String(),
    'done': done,
  };
}

class AppState extends ChangeNotifier {
  Plot? plot;
  PowerResult? weather;
  final power = PowerService();
  bool loading = false;
  String? error, storageError;
  int _request = 0;
  List<Crop> rotation = [crops[0], crops[2], crops[1]];
  int years = 5;
  bool cover = true;
  final List<FarmTask> tasks = [];
  final Set<String> strategies = {};
  AppState() {
    try {
      final raw = readLocal('plot');
      if (raw != null) plot = Plot.fromJson(jsonDecode(raw));
      final plan = readLocal('plan');
      if (plan != null) {
        final j = jsonDecode(plan);
        rotation = (j['crops'] as List)
            .map((name) => crops.firstWhere((c) => c.name == name))
            .toList();
        years = [3, 5, 10].contains(j['years']) ? j['years'] : 5;
        cover = j['cover'] == true;
      }
      final savedTasks = readLocal('tasks');
      if (savedTasks != null) {
        for (final j in jsonDecode(savedTasks)) {
          tasks.add(
            FarmTask(j['name'], DateTime.parse(j['date']), done: j['done']),
          );
        }
      }
      final savedStrategies = readLocal('strategies');
      if (savedStrategies != null) {
        strategies.addAll((jsonDecode(savedStrategies) as List).cast<String>());
      }
    } catch (_) {
      storageError =
          'No se pudo recuperar parte del registro local. Puedes volver a guardarlo.';
    }
  }
  void persist(String key, String value) {
    try {
      writeLocal(key, value);
      storageError = null;
    } catch (_) {
      storageError =
          'El navegador impidió guardar los cambios. Se conservarán solo en esta sesión.';
    }
  }

  void saveEconomy(String value) {
    persist('economy', value);
    notifyListeners();
  }

  void savePlot(Plot value) {
    plot = value;
    weather = null;
    error = null;
    loading = false;
    _request++;
    persist('plot', value.encode());
    notifyListeners();
  }

  Future<void> fetchWeather(DateTime start, DateTime end) async {
    final p = plot;
    if (p == null || loading) return;
    final id = ++_request;
    loading = true;
    error = null;
    weather = null;
    notifyListeners();
    try {
      final result = await power.fetch(p.latitude, p.longitude, start, end);
      if (id == _request) weather = result;
    } catch (e) {
      if (id == _request) {
        error =
            'No se pudo consultar NASA POWER. Comprueba la conexión y que el servidor esté iniciado. Detalle: $e';
      }
    } finally {
      if (id == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void recentWeather() {
    final now = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final end = DateTime.utc(now.year, now.month, now.day);
    fetchWeather(end.subtract(const Duration(days: 29)), end);
  }

  void savePlan(List<Crop> plan, int horizon, bool coverage) {
    rotation = List.of(plan);
    years = horizon;
    cover = coverage;
    persist(
      'plan',
      jsonEncode({
        'crops': rotation.map((c) => c.name).toList(),
        'years': years,
        'cover': cover,
      }),
    );
    notifyListeners();
  }

  void addTask(String name, DateTime date) {
    tasks.add(FarmTask(name, date));
    saveTasks();
  }

  void toggleTask(FarmTask task) {
    task.done = !task.done;
    saveTasks();
  }

  void saveTasks() {
    persist('tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
    notifyListeners();
  }

  void toggleStrategy(String name) {
    if (!strategies.add(name)) strategies.remove(name);
    persist('strategies', jsonEncode(strategies.toList()));
    notifyListeners();
  }

  @override
  void dispose() {
    power.dispose();
    super.dispose();
  }
}
