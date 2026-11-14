import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../main.dart' show copyText;
import 'widgets.dart';

class PlotScreen extends StatefulWidget {
  final AppState state;
  const PlotScreen({super.key, required this.state});
  @override
  State<PlotScreen> createState() => _PlotScreenState();
}

class _PlotScreenState extends State<PlotScreen> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  String soil = 'Sin análisis',
      water = 'Secano',
      previous = 'Sin registro',
      priority = 'Regenerar el suelo';
  double latitude = -13.519, longitude = -71.978;
  @override
  void initState() {
    super.initState();
    final p = widget.state.plot;
    final values = {
      'name': p?.name ?? '',
      'department': p?.department ?? '',
      'province': p?.province ?? '',
      'district': p?.district ?? '',
      'latitude': p?.latitude.toString() ?? '',
      'longitude': p?.longitude.toString() ?? '',
      'area': p?.area.toString() ?? '',
      'altitude': p?.altitude?.toString() ?? '',
      'ph': p?.ph?.toString() ?? '',
      'organicMatter': p?.organicMatter?.toString() ?? '',
    };
    for (final e in values.entries) {
      fields[e.key] = TextEditingController(text: e.value);
    }
    if (p != null) {
      latitude = p.latitude;
      longitude = p.longitude;
      soil = p.soil;
      water = p.water;
      previous = p.previous;
      priority = p.priority;
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
    String key,
    String label, {
    bool required = false,
    double? min,
    double? max,
    String? helper,
  }) => TextFormField(
    controller: fields[key],
    decoration: InputDecoration(labelText: label, helperText: helper),
    keyboardType: min == null
        ? TextInputType.text
        : const TextInputType.numberWithOptions(decimal: true, signed: true),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return required ? 'Completa este campo' : null;
      if (min != null) {
        final n = double.tryParse(text.replaceAll(',', '.'));
        if (n == null || !n.isFinite || n < min || (max != null && n > max)) {
          return 'Ingresa un valor entre $min y $max';
        }
      }
      return null;
    },
    onChanged: key == 'latitude' || key == 'longitude'
        ? (_) {
            final a = double.tryParse(
                  fields['latitude']!.text.replaceAll(',', '.'),
                ),
                b = double.tryParse(
                  fields['longitude']!.text.replaceAll(',', '.'),
                );
            if (a != null &&
                b != null &&
                a.isFinite &&
                b.isFinite &&
                a.abs() <= 85 &&
                b.abs() <= 180) {
              setState(() {
                latitude = a;
                longitude = b;
              });
            }
          }
        : null,
  );
  Widget select(
    String label,
    String value,
    List<String> items,
    void Function(String) change,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: items
        .map(
          (s) => DropdownMenuItem(
            value: s,
            child: Text(
              s,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        )
        .toList(),
    onChanged: (v) => setState(() => change(v!)),
  );
  double? number(String key) =>
      double.tryParse(fields[key]!.text.replaceAll(',', '.'));
  void save() {
    if (!form.currentState!.validate()) return;
    widget.state.savePlot(
      Plot(
        name: fields['name']!.text.trim(),
        department: fields['department']!.text.trim(),
        province: fields['province']!.text.trim(),
        district: fields['district']!.text.trim(),
        latitude: number('latitude')!,
        longitude: number('longitude')!,
        area: number('area')!,
        altitude: number('altitude'),
        ph: number('ph'),
        organicMatter: number('organicMatter'),
        soil: soil,
        water: water,
        previous: previous,
        priority: priority,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.state.storageError ?? 'Parcela guardada en este navegador',
        ),
      ),
    );
    setState(() {});
  }

  Future<void> importPlot() async {
    final controller = TextEditingController();
    String? message;
    final restored = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Restaurar una parcela'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Pega el respaldo JSON',
                  ),
                ),
                if (message != null)
                  Text(message!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final p = Plot.fromJson(jsonDecode(controller.text));
                  if (!p.latitude.isFinite ||
                      !p.longitude.isFinite ||
                      p.latitude.abs() > 90 ||
                      p.longitude.abs() > 180 ||
                      !p.area.isFinite ||
                      p.area <= 0 ||
                      p.name.trim().isEmpty ||
                      (p.altitude != null &&
                          (!p.altitude!.isFinite ||
                              p.altitude! < -500 ||
                              p.altitude! > 9000)) ||
                      (p.ph != null &&
                          (!p.ph!.isFinite || p.ph! < 0 || p.ph! > 14)) ||
                      (p.organicMatter != null &&
                          (!p.organicMatter!.isFinite ||
                              p.organicMatter! < 0 ||
                              p.organicMatter! > 100))) {
                    throw const FormatException('Valores fuera de rango');
                  }
                  widget.state.savePlot(p);
                  Navigator.pop(context, true);
                } catch (_) {
                  update(
                    () => message =
                        'El respaldo no tiene el formato o los valores esperados.',
                  );
                }
              },
              child: const Text('Restaurar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    // Re-open with restored fields; avoids silently replacing edits while typing.
    if (restored == true && mounted && widget.state.plot != null) {
      final p = widget.state.plot!;
      final j = p.toJson();
      for (final key in fields.keys) {
        fields[key]!.text = j[key]?.toString() ?? '';
      }
      setState(() {
        latitude = p.latitude;
        longitude = p.longitude;
        soil =
            ['Sin análisis', 'Arenoso', 'Franco', 'Arcilloso'].contains(p.soil)
            ? p.soil
            : 'Sin análisis';
        water =
            ['Secano', 'Riego estacional', 'Riego permanente'].contains(p.water)
            ? p.water
            : 'Secano';
        previous =
            ['Sin registro', ...crops.map((c) => c.name)].contains(p.previous)
            ? p.previous
            : 'Sin registro';
        priority =
            [
              'Regenerar el suelo',
              'Ahorrar agua',
              'Diversificar cultivos',
              'Mejorar ingresos',
            ].contains(p.priority)
            ? p.priority
            : 'Regenerar el suelo';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Notice(
          'Haz clic en el mapa para elegir un punto de referencia o ingresa las coordenadas. La vista inicial muestra Cusco como referencia; no constituye una parcela registrada. Superficie y altitud son datos aportados por ti.',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '01 / Ubica tu tierra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 320,
                child: PlotMap(
                  latitude: latitude,
                  longitude: longitude,
                  onSelect: (a, b) => setState(() {
                    latitude = a;
                    longitude = b;
                    fields['latitude']!.text = a.toStringAsFixed(6);
                    fields['longitude']!.text = b.toStringAsFixed(6);
                  }),
                ),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minWidth: 250,
                children: [
                  field('name', 'Nombre de la parcela', required: true),
                  field('department', 'Departamento', required: true),
                  field('province', 'Provincia', required: true),
                  field('district', 'Distrito', required: true),
                  field(
                    'latitude',
                    'Latitud',
                    required: true,
                    min: -90,
                    max: 90,
                  ),
                  field(
                    'longitude',
                    'Longitud',
                    required: true,
                    min: -180,
                    max: 180,
                  ),
                  field(
                    'area',
                    'Superficie (hectáreas)',
                    required: true,
                    min: .0001,
                    max: 1000000,
                  ),
                  field(
                    'altitude',
                    'Altitud (m s. n. m.) · opcional',
                    min: -500,
                    max: 9000,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '02 / Cuenta su historia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'No conocer un dato también es un buen punto de partida.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minWidth: 250,
                children: [
                  select('Textura del suelo (aportada)', soil, [
                    'Sin análisis',
                    'Arenoso',
                    'Franco',
                    'Arcilloso',
                  ], (v) => soil = v),
                  select('Disponibilidad de agua', water, [
                    'Secano',
                    'Riego estacional',
                    'Riego permanente',
                  ], (v) => water = v),
                  select('Cultivo anterior', previous, [
                    'Sin registro',
                    ...crops.map((c) => c.name),
                  ], (v) => previous = v),
                  select('Tu prioridad', priority, [
                    'Regenerar el suelo',
                    'Ahorrar agua',
                    'Diversificar cultivos',
                    'Mejorar ingresos',
                  ], (v) => priority = v),
                  field('ph', 'pH · solo si tienes análisis', min: 0, max: 14),
                  field(
                    'organicMatter',
                    'Materia orgánica (%) · análisis local',
                    min: 0,
                    max: 100,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: save,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Guardar mi parcela'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.state.plot == null
                        ? null
                        : () => copyText(
                            context,
                            const JsonEncoder.withIndent(
                              '  ',
                            ).convert(widget.state.plot!.toJson()),
                          ),
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copiar respaldo'),
                  ),
                  TextButton(
                    onPressed: importPlot,
                    child: const Text('Restaurar respaldo'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.state.plot != null) ...[
          const SizedBox(height: 20),
          Panel(
            color: const Color(0xFFEBEFDF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.state.plot!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.state.plot!.region),
                const SizedBox(height: 8),
                Text(
                  'Fuente: registro del agricultor · ${dateLabel(widget.state.plot!.updatedAt)}\npH: ${widget.state.plot!.ph ?? "pendiente"} · N/P/K: pendiente de laboratorio\nLa región altitudinal es orientativa; la vertiente requiere confirmación local.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: muted,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
