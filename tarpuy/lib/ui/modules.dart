import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Simulation;
import '../data/app_state.dart';
import '../data/models.dart';
import '../data/storage.dart';
import '../main.dart' show copyText;
import '../services/astronomy.dart';
import '../services/nasa/power.dart';
import '../services/nasa/smap.dart';
import '../services/nasa/gpm.dart';
import '../services/nasa/modis.dart';
import '../services/nasa/landsat.dart';
import 'widgets.dart';

const months = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class CalendarScreen extends StatefulWidget {
  final AppState state;
  const CalendarScreen({super.key, required this.state});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int month = DateTime.now().month, year = DateTime.now().year;
  String crop = 'Todos';
  Future<void> addTask() async {
    final name = TextEditingController();
    DateTime date = DateTime(year, month, 1);
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Una nueva actividad'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: '¿Qué necesitas hacer?',
                    ),
                    validator: (s) => s == null || s.trim().isEmpty
                        ? 'Escribe una actividad'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) update(() => date = picked);
                    },
                    icon: const Icon(Icons.event),
                    label: Text(dateLabel(date)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                widget.state.addTask(name.text.trim(), date);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.state.plot;
    final sow = p == null ? <int>[] : sowingMonths(p);
    final suitable = p == null
        ? <Crop>[]
        : crops.where((c) => c.fits(p)).toList();
    final visible = suitable
        .where((c) => crop == 'Todos' || c.name == crop)
        .toList();
    final first = DateTime(year, month, 1);
    final days = DateTime(year, month + 1, 0).day;
    final offset = first.weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Notice(
          p == null
              ? 'Registra la parcela para habilitar el catálogo por altitud. Puedes organizar tareas desde ahora.'
              : 'Calendario orientativo para ${p.name}: ${p.region}, ${p.water.toLowerCase()}. Las ventanas usan reglas amplias de altitud y agua; no sustituyen un calendario validado por distrito, variedad y clima. Con riego permanente, una ventana anual no implica aptitud térmica todo el año.',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: month,
                      decoration: const InputDecoration(labelText: 'Mes'),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(months[i]),
                        ),
                      ),
                      onChanged: (v) => setState(() => month = v!),
                    ),
                  ),
                  SizedBox(
                    width: 145,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: year,
                      decoration: const InputDecoration(labelText: 'Año'),
                      items:
                          List.generate(12, (i) => DateTime.now().year - 1 + i)
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('$y'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => year = v!),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: addTask,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Añadir actividad'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, box) => Wrap(
                  children: List.generate(((days + offset) / 7).ceil() * 7, (
                    i,
                  ) {
                    final day = i - offset + 1;
                    final valid = day > 0 && day <= days;
                    final date = DateTime(year, month, day);
                    final tasks = widget.state.tasks
                        .where(
                          (t) =>
                              t.date.year == year &&
                              t.date.month == month &&
                              t.date.day == day,
                        )
                        .toList();
                    return SizedBox(
                      width: box.maxWidth / 7,
                      height: box.maxWidth < 450 ? 53 : 83,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: !valid
                              ? Colors.transparent
                              : tasks.isNotEmpty
                              ? const Color(0xFFE8EEDB)
                              : cream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: valid
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$day',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (tasks.isNotEmpty)
                                    Expanded(
                                      child: Tooltip(
                                        message: tasks
                                            .map((t) => t.name)
                                            .join('\n'),
                                        child: Text(
                                          box.maxWidth < 450
                                              ? '•'
                                              : '${tasks.length} actividad${tasks.length > 1 ? "es" : ""}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (box.maxWidth > 450 && day % 7 == 1)
                                    Text(
                                      lunarPhase(date),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 8,
                                      ),
                                    ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                sow.contains(month)
                    ? 'Ventana de siembra orientativa · confirmar clima y variedad'
                    : 'Sin ventana sugerida para este mes con los datos disponibles.',
                style: const TextStyle(color: green, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu agenda de campo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (widget.state.tasks
                  .where((t) => t.date.month == month && t.date.year == year)
                  .isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Aún no tienes actividades para este mes.',
                    style: TextStyle(color: muted),
                  ),
                ),
              ...widget.state.tasks
                  .where((t) => t.date.month == month && t.date.year == year)
                  .map(
                    (t) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: t.done,
                      onChanged: (_) =>
                          setState(() => widget.state.toggleTask(t)),
                      title: Text(
                        t.name,
                        style: TextStyle(
                          decoration: t.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(dateLabel(t.date)),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cultivos para explorar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: crop,
                decoration: const InputDecoration(labelText: 'Filtrar cultivo'),
                items: ['Todos', ...suitable.map((c) => c.name)]
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) => setState(() => crop = v!),
              ),
              const SizedBox(height: 20),
              if (visible.isEmpty)
                const Text(
                  'Falta altitud o no hay cultivos en el catálogo para ese rango.',
                  style: TextStyle(color: muted),
                ),
              ResponsiveGrid(
                minWidth: 240,
                children: visible
                    .map(
                      (c) => Panel(
                        color: cream,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${c.family} · ${c.days} días de ciclo ilustrativo\nAgua: ${c.water} · Demanda nutricional: ${c.nutrition}\nAltitud orientativa: ${c.minAltitude}–${c.maxAltitude} m',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.8,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              sow.isEmpty
                                  ? 'Siembra: pendiente de datos'
                                  : 'Siembra: ${sow.map((m) => months[m - 1].substring(0, 3)).join(" · ")}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: green,
                              ),
                            ),
                            Text(
                              sow.contains(month)
                                  ? 'Si siembras el 1/${month.toString().padLeft(2, "0")}: cosecha ilustrativa ${dateLabel(DateTime(year, month, 1).add(Duration(days: c.days)))}'
                                  : 'Cosecha: depende de tu fecha de siembra',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Manejo: revisar humedad, cobertura y sanidad. Confirmar temperatura óptima y fertilización por variedad y análisis.',
                              style: TextStyle(color: muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RotationScreen extends StatefulWidget {
  final AppState state;
  const RotationScreen({super.key, required this.state});
  @override
  State<RotationScreen> createState() => _RotationScreenState();
}

class _RotationScreenState extends State<RotationScreen> {
  late List<Crop> plan = List.of(widget.state.rotation);
  late int years = widget.state.years;
  late bool cover = widget.state.cover;
  @override
  Widget build(BuildContext context) {
    final baseline = simulate([plan.first], years, cover: false);
    final proposed = simulate(plan, years, cover: cover);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Notice(
          'Simulación didáctica, sin calibración de campo. Los índices comparan supuestos; no predicen rendimientos, nitrógeno en kg/ha ni recuperación real del suelo. Se asume un cultivo por año y la repetición de tu secuencia.',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diseña una secuencia con futuro',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'El orden importa. Alterna familias y explora el papel de las leguminosas.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                children: [3, 5, 10]
                    .map(
                      (y) => ChoiceChip(
                        label: Text('$y años'),
                        selected: years == y,
                        onSelected: (_) => setState(() => years = y),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              ...List.generate(
                plan.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 74,
                        child: Text(
                          'Paso ${i + 1}',
                          style: const TextStyle(color: green),
                        ),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('$i-${plan[i].name}'),
                          initialValue: plan[i].name,
                          decoration: const InputDecoration(
                            labelText: 'Cultivo de la secuencia',
                          ),
                          isExpanded: true,
                          items: crops
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () =>
                                plan[i] = crops.firstWhere((c) => c.name == v),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar paso',
                        onPressed: plan.length > 1
                            ? () => setState(() => plan.removeAt(i))
                            : null,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: plan.length < 6
                        ? () => setState(() => plan.add(crops[1]))
                        : null,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Añadir cultivo'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      widget.state.savePlan(plan, years, cover);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.state.storageError ??
                                'Escenario guardado. Disponible en Impacto ambiental.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Guardar escenario'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Mantener cobertura entre cultivos',
                  style: TextStyle(fontSize: 13),
                ),
                value: cover,
                onChanged: (v) => setState(() => cover = v),
              ),
              if (widget.state.plot != null &&
                  plan.any((c) => !c.fits(widget.state.plot!)))
                const Notice(
                  'Algún cultivo queda fuera del rango altitudinal del catálogo o falta altitud. La herramienta permite explorar el escenario, pero no lo considera una recomendación.',
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  years,
                  (i) => Tag('Año ${i + 1} · ${plan[i % plan.length].name}'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        comparisonPanel(baseline, proposed),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lo que hay detrás de cada número',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Leguminosas en el plan: ${proposed.legumes}. Aporte potencial de N: cualitativo, condicionado a nodulación y manejo.\nRepeticiones consecutivas de familia: ${proposed.familyRepeats}.\nRaíces: ${plan.map((c) => "${c.name}: ${c.roots.toLowerCase()}").join("; ")}.\nDemanda nutricional: ${plan.map((c) => "${c.name}: ${c.nutrition.toLowerCase()}").join("; ")}.\nConsumo de agua: índice alto/medio/bajo de 90/60/35 promediado.\nCobertura: supuesto de 75 con cobertura, 35 sin cobertura + 10 × proporción de leguminosas.\nErosión: 100 − cobertura + 4 × repeticiones de familia, limitado a 0–100.\nCambio de materia orgánica: +0,04 puntos/año con cobertura, −0,02 sin cobertura; +0,03 por año de leguminosa y −0,015 por repetición. Coeficientes ilustrativos, sin evidencia de calibración para tu parcela.',
                style: const TextStyle(fontSize: 12, height: 1.9, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget comparisonPanel(Simulation baseline, Simulation proposed) => Panel(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Dos caminos para tu terreno',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      const Text(
        'Referencia: monocultivo del primer cultivo sin cobertura · Propuesta: tu secuencia',
        style: TextStyle(fontSize: 11, color: muted),
      ),
      const SizedBox(height: 20),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Indicador simulado')),
            DataColumn(label: Text('Referencia')),
            DataColumn(label: Text('Propuesta')),
          ],
          rows: [
            DataRow(
              cells: [
                const DataCell(Text('Familias botánicas')),
                DataCell(Text(baseline.diversity.round().toString())),
                DataCell(Text(proposed.diversity.round().toString())),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Demanda hídrica · índice /100')),
                DataCell(Text(baseline.waterIndex.toStringAsFixed(0))),
                DataCell(Text(proposed.waterIndex.toStringAsFixed(0))),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Cobertura · índice /100')),
                DataCell(Text(baseline.cover.toStringAsFixed(0))),
                DataCell(Text(proposed.cover.toStringAsFixed(0))),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Erosión · índice /100')),
                DataCell(Text(baseline.erosionIndex.toStringAsFixed(0))),
                DataCell(Text(proposed.erosionIndex.toStringAsFixed(0))),
              ],
            ),
            DataRow(
              cells: [
                const DataCell(Text('Δ materia orgánica · puntos %')),
                DataCell(Text(baseline.organicChange.toStringAsFixed(2))),
                DataCell(Text(proposed.organicChange.toStringAsFixed(2))),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
);

class Strategy {
  final String name, conditions, benefit, resource;
  final IconData icon;
  const Strategy(
    this.name,
    this.conditions,
    this.benefit,
    this.resource,
    this.icon,
  );
}

const strategies = [
  Strategy(
    'Andenes y terrazas',
    'Laderas con evaluación de pendiente, drenaje y estabilidad. Requiere diseño técnico.',
    'Reducir escorrentía y conservar suelo.',
    'Inversión alta · trabajo comunitario',
    Icons.landscape_outlined,
  ),
  Strategy(
    'Cultivos de cobertura',
    'Elegir especies adaptadas y evitar competencia por agua en secano.',
    'Proteger la superficie y aportar residuos.',
    'Inversión baja a media · semillas',
    Icons.grass,
  ),
  Strategy(
    'Asociación de cultivos',
    'Compatibilidad de ciclos, luz, agua y labores de cosecha.',
    'Diversificar producción y ocupación del espacio.',
    'Inversión media · planificación',
    Icons.spa_outlined,
  ),
  Strategy(
    'Rotación con leguminosas',
    'Variedad local, nodulación efectiva y manejo de residuos.',
    'Fijación potencial de N y diversidad de familias.',
    'Inversión baja a media · semilla adaptada',
    Icons.autorenew,
  ),
  Strategy(
    'Agroforestería',
    'Especies arbóreas compatibles con altitud, agua y uso del terreno.',
    'Cobertura, hábitat y productos a largo plazo.',
    'Inversión media a alta · horizonte largo',
    Icons.park_outlined,
  ),
  Strategy(
    'Agricultura de conservación',
    'Cobertura, diversidad y reducción de remoción según suelo y maquinaria.',
    'Conservar estructura y disminuir exposición.',
    'Inversión variable · adaptación de labores',
    Icons.eco_outlined,
  ),
  Strategy(
    'Hidroponía complementaria',
    'Agua de calidad, energía, nutrientes controlados y acceso a mercado.',
    'Producción complementaria en espacios limitados; no regenera por sí sola el suelo.',
    'Inversión alta · control técnico',
    Icons.water_outlined,
  ),
  Strategy(
    'Recuperación de suelos',
    'Diagnóstico de pH, salinidad, compactación y materia orgánica.',
    'Elegir enmiendas y manejo según la causa.',
    'Inversión variable · análisis de laboratorio',
    Icons.science_outlined,
  ),
  Strategy(
    'Riego eficiente',
    'Disponibilidad, filtrado, presión y programación basada en mediciones.',
    'Disminuir pérdidas y aplicar agua donde se necesita.',
    'Inversión media a alta · mantenimiento',
    Icons.water_drop_outlined,
  ),
];

class RegenerationScreen extends StatefulWidget {
  final AppState state;
  const RegenerationScreen({super.key, required this.state});
  @override
  State<RegenerationScreen> createState() => _RegenerationScreenState();
}

class _RegenerationScreenState extends State<RegenerationScreen> {
  bool selectedOnly = false;
  @override
  Widget build(BuildContext context) {
    final selected = strategies
        .where((s) => widget.state.strategies.contains(s.name))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Notice(
          'Catálogo educativo. La selección conserva tus alternativas, pero no certifica viabilidad. Confirma las condiciones con una evaluación del terreno y un presupuesto local.',
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Saberes que regeneran',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            FilterChip(
              label: Text('Mi selección (${selected.length})'),
              selected: selectedOnly,
              onSelected: (v) => setState(() => selectedOnly = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (selectedOnly && selected.isEmpty)
          const Panel(
            child: Text('Selecciona alternativas para compararlas aquí.'),
          ),
        ResponsiveGrid(
          minWidth: 300,
          children: (selectedOnly ? selected : strategies)
              .map(
                (s) => Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(s.icon, color: green, size: 30),
                      const SizedBox(height: 18),
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.benefit,
                        style: const TextStyle(fontSize: 12, height: 1.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.conditions,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 11,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.resource,
                        style: const TextStyle(color: green, fontSize: 10),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => widget.state.toggleStrategy(s.name)),
                        icon: Icon(
                          widget.state.strategies.contains(s.name)
                              ? Icons.check
                              : Icons.add,
                          size: 16,
                        ),
                        label: Text(
                          widget.state.strategies.contains(s.name)
                              ? 'Seleccionada'
                              : 'Comparar alternativa',
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 20),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparación de tus alternativas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.state.plot == null
                      ? 'Parcela pendiente: registra agua, suelo y superficie.'
                      : '${widget.state.plot!.name} · ${widget.state.plot!.area} ha · ${widget.state.plot!.water}\nSuelo aportado: ${widget.state.plot!.soil} · prioridad: ${widget.state.plot!.priority}',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 12),
                ...selected.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '${s.name}\n${s.resource}\nCondición a verificar: ${s.conditions}',
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class NasaScreen extends StatefulWidget {
  final AppState state;
  const NasaScreen({super.key, required this.state});
  @override
  State<NasaScreen> createState() => _NasaScreenState();
}

class _NasaScreenState extends State<NasaScreen> {
  late DateTime end = DateTime.now().toUtc().subtract(const Duration(days: 7));
  late DateTime start = end.subtract(const Duration(days: 29));
  String variable = 'T2M';
  Future<void> pick(bool isStart) async {
    final today = DateTime.now().toUtc();
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? start : end,
      firstDate: DateTime(1981),
      lastDate: today,
    );
    if (selected != null) {
      setState(() {
        final day = DateTime.utc(selected.year, selected.month, selected.day);
        if (isStart) {
          start = day;
        } else {
          end = day;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalid = start.isAfter(end) || end.difference(start).inDays > 366;
    final result = widget.state.weather;
    final labels = {
      'T2M': 'Temperatura media',
      'T2M_MAX': 'Temperatura máxima',
      'T2M_MIN': 'Temperatura mínima',
      'PRECTOTCORR': 'Precipitación',
      'RH2M': 'Humedad relativa del aire',
      'ALLSKY_SFC_SW_DWN': 'Radiación solar',
    };
    final rows =
        result?.measurements.where((m) => m.variable == variable).toList() ??
        [];
    rows.sort((a, b) => b.observationDate.compareTo(a.observationDate));
    final groups = <int, List<double>>{};
    for (final row in rows) {
      if (row.value != null) {
        groups.putIfAbsent(row.observationDate.month, () => []).add(row.value!);
      }
    }
    final sortedMonths = groups.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          color: forest,
          child: const Row(
            children: [
              Icon(Icons.satellite_alt, color: lime, size: 40),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Una perspectiva desde el espacio.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Consulta series ambientales y conoce el alcance de cada fuente.',
                      style: TextStyle(color: Color(0xFFC5D7C4), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Tag('CONECTOR IMPLEMENTADO · NASA POWER'),
              const SizedBox(height: 16),
              const Text(
                'Clima para las coordenadas de tu parcela',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                widget.state.plot == null
                    ? 'Primero registra una parcela en Mi terreno.'
                    : '${widget.state.plot!.latitude}, ${widget.state.plot!.longitude} · ${widget.state.plot!.name}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.state.loading ? null : () => pick(true),
                    icon: const Icon(Icons.event, size: 16),
                    label: Text('Desde ${dateLabel(start)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.state.loading ? null : () => pick(false),
                    icon: const Icon(Icons.event, size: 16),
                    label: Text('Hasta ${dateLabel(end)}'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        widget.state.plot == null ||
                            widget.state.loading ||
                            invalid
                        ? null
                        : () => widget.state.fetchWeather(start, end),
                    icon: widget.state.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 16),
                    label: Text(
                      widget.state.loading
                          ? 'Consultando NASA…'
                          : 'Consultar datos',
                    ),
                  ),
                ],
              ),
              if (invalid)
                const Notice(
                  'El inicio debe preceder al fin y el periodo no debe superar 366 días.',
                ),
              if (widget.state.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(),
                ),
              if (widget.state.error != null) Notice(widget.state.error!),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: variable,
                decoration: const InputDecoration(
                  labelText: 'Variable ambiental',
                ),
                isExpanded: true,
                items: labels.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => variable = v!),
              ),
              const SizedBox(height: 25),
              ClimateChart(
                data: result?.measurements ?? [],
                variable: variable,
              ),
              const SizedBox(height: 16),
              Text(
                result == null
                    ? 'Sin datos consultados. No se generan series de demostración.'
                    : 'Consulta: ${dateLabel(result.fetchedAt)} ${result.fetchedAt.hour.toString().padLeft(2, "0")}:${result.fetchedAt.minute.toString().padLeft(2, "0")} UTC · ${rows.where((m) => m.value != null).length}/${rows.length} registros disponibles.\nFuente: NASA POWER · estimado regional · resolución diaria UTC. Unidades conservadas de la respuesta oficial. Resolución espacial variable según parámetro; no representa un sensor en tu parcela.',
                style: const TextStyle(color: muted, fontSize: 11, height: 1.7),
              ),
              const SizedBox(height: 10),
              const SelectableText(
                powerSource,
                style: TextStyle(fontSize: 10, color: green),
              ),
              if (result != null)
                TextButton.icon(
                  onPressed: () {
                    final header =
                        'datasetId,provider,variable,value,unit,latitude,longitude,observationDate,fetchedAt,type,qualityFlag,sourceUrl';
                    String csv(String value) =>
                        '"${value.replaceAll('"', '""')}"';
                    final data = result.measurements
                        .map(
                          (m) => [
                            m.datasetId,
                            m.provider,
                            m.variable,
                            m.value?.toString() ?? '',
                            m.unit,
                            '${m.latitude}',
                            '${m.longitude}',
                            m.observationDate.toIso8601String(),
                            m.fetchedAt.toIso8601String(),
                            m.type,
                            m.qualityFlag,
                            m.sourceUrl,
                          ].map(csv).join(','),
                        )
                        .join('\n');
                    copyText(context, '$header\n$data');
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar serie CSV con procedencia'),
                ),
            ],
          ),
        ),
        if (groups.isNotEmpty) ...[
          const SizedBox(height: 20),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparación por mes de la serie consultada',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Agrupa únicamente los días disponibles. Un mes parcial no equivale a una climatología ni a una estación completa.',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
                const SizedBox(height: 16),
                ...sortedMonths.map((m) {
                  final vals = groups[m]!;
                  final total = vals.reduce((a, b) => a + b);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          months[m - 1],
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: vals.length / 31,
                          backgroundColor: cream,
                          color: green,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(variable == "PRECTOTCORR" ? total : total / vals.length).toStringAsFixed(1)} ${rows.firstWhere((r) => r.value != null).unit} · ${vals.length} días',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const Notice(
          'POWER ofrece estimaciones ambientales regionales, no pronósticos ni mediciones químicas del suelo. Los valores faltantes se conservan como no disponibles. Para fechas recientes, algunas variables pueden llegar con retraso.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Próximas capas de observación',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minWidth: 280,
          children: [SmapSource(), GpmSource(), ModisSource(), LandsatSource()]
              .map(
                (source) => Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Tag('INTEGRACIÓN PENDIENTE', color: gold),
                      const SizedBox(height: 15),
                      Text(
                        source.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        source.datasetId,
                        style: const TextStyle(fontSize: 10, color: green),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        source.description,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.7,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        source.resolution,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        source.url,
                        style: const TextStyle(fontSize: 10, color: green),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const Notice(
          'SRTM y GLDAS/FLDAS: fuentes previstas, sin conector. Las capas temáticas, el polígono de parcela y el procesamiento de escenas satelitales requieren una fase adicional. El mapa actual es cartografía base OpenStreetMap.',
        ),
      ],
    );
  }
}

class EconomyScreen extends StatefulWidget {
  final AppState state;
  const EconomyScreen({super.key, required this.state});
  @override
  State<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends State<EconomyScreen> {
  final key = GlobalKey<FormState>();
  final price = TextEditingController(),
      cost = TextEditingController(),
      yieldKg = TextEditingController(),
      quoteSource = TextEditingController();
  String crop = 'Papa', market = 'Local';
  DateTime quoteDate = DateTime.now();
  final List<Map<String, dynamic>> scenarios = [];
  @override
  void initState() {
    super.initState();
    try {
      final saved = readLocal('economy');
      if (saved != null) {
        scenarios.addAll(
          (jsonDecode(saved) as List).cast<Map<String, dynamic>>(),
        );
      }
    } catch (_) {
      /* Invalid browser data does not become a market quote. */
    }
  }

  @override
  void dispose() {
    price.dispose();
    cost.dispose();
    yieldKg.dispose();
    quoteSource.dispose();
    super.dispose();
  }

  Widget input(TextEditingController c, String label) => TextFormField(
    controller: c,
    decoration: InputDecoration(labelText: label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (s) {
      final n = double.tryParse((s ?? '').replaceAll(',', '.'));
      return n == null || !n.isFinite || n < 0 || n > 1e10
          ? 'Ingresa un número positivo válido'
          : null;
    },
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Notice(
        'No hay una fuente de precios conectada. Ingresa tus cotizaciones en soles y costos propios. Los resultados son escenarios aritméticos, no precios actuales ni pronósticos de demanda o rendimiento.',
      ),
      Panel(
        child: Form(
          key: key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pon tus decisiones en números',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minWidth: 260,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: crop,
                    decoration: const InputDecoration(labelText: 'Cultivo'),
                    items: crops
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => crop = v!),
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: market,
                    decoration: const InputDecoration(
                      labelText: 'Mercado de referencia',
                    ),
                    items: ['Local', 'Nacional', 'Internacional']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => market = v!),
                  ),
                  input(price, 'Cotización aportada (S/ por kg)'),
                  input(cost, 'Costo total de la parcela (S/)'),
                  input(yieldKg, 'Cosecha total supuesta (kg)'),
                  TextFormField(
                    controller: quoteSource,
                    decoration: const InputDecoration(
                      labelText: 'Fuente de tu cotización',
                    ),
                    validator: (s) => s == null || s.trim().isEmpty
                        ? 'Indica proveedor, mercado o supuesto'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: quoteDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => quoteDate = d);
                },
                icon: const Icon(Icons.event, size: 16),
                label: Text('Fecha de cotización: ${dateLabel(quoteDate)}'),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  if (!key.currentState!.validate()) return;
                  final p = double.parse(price.text.replaceAll(',', '.')),
                      c = double.parse(cost.text.replaceAll(',', '.')),
                      y = double.parse(yieldKg.text.replaceAll(',', '.'));
                  setState(
                    () => scenarios.add({
                      'crop': crop,
                      'market': market,
                      'price': p,
                      'cost': c,
                      'yield': y,
                      'source': quoteSource.text.trim(),
                      'date': quoteDate.toIso8601String(),
                    }),
                  );
                  widget.state.saveEconomy(jsonEncode(scenarios));
                },
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calcular y guardar escenario'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      if (scenarios.isEmpty)
        const Panel(
          child: Text(
            'Aún no has calculado escenarios. No se han precargado precios de ejemplo.',
            style: TextStyle(color: muted),
          ),
        ),
      ResponsiveGrid(
        minWidth: 300,
        children: scenarios.map((s) {
          final revenue = (s['price'] as num) * (s['yield'] as num),
              margin = revenue - (s['cost'] as num);
          return Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s['crop'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar escenario',
                      onPressed: () {
                        setState(() => scenarios.remove(s));
                        widget.state.saveEconomy(jsonEncode(scenarios));
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
                Tag('${s["market"]} · aportado por el usuario'),
                const SizedBox(height: 18),
                Text(
                  'S/ ${margin.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    color: margin >= 0 ? green : Colors.brown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Margen bruto del escenario',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingresos: S/ ${revenue.toStringAsFixed(2)}\nCosto total: S/ ${s["cost"]}\nCosecha supuesta: ${s["yield"]} kg\nCotización: S/ ${s["price"]}/kg\nFuente: ${s["source"]}\nFecha: ${dateLabel(DateTime.parse(s["date"]))}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: muted,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No incluye costos omitidos por el usuario, impuestos, financiamiento ni pérdidas adicionales.',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      const Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuentes y cobertura pendientes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Precios actuales e históricos: pendiente de conexión a MIDAGRI/SISAP y mercados.\nDemanda: sin información conectada.\nComercio internacional: pendiente; esta versión no convierte monedas.\nLas cotizaciones que registres quedan como historial local, identificadas por mercado, fuente y fecha.',
              style: TextStyle(fontSize: 12, color: muted, height: 1.8),
            ),
          ],
        ),
      ),
    ],
  );
}

class AstronomyScreen extends StatefulWidget {
  final AppState state;
  const AstronomyScreen({super.key, required this.state});
  @override
  State<AstronomyScreen> createState() => _AstronomyScreenState();
}

class _AstronomyScreenState extends State<AstronomyScreen> {
  DateTime date = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final p = widget.state.plot;
    final solar = p == null ? null : solarDay(date, p.latitude, p.longitude);
    final age = lunarAge(DateTime.utc(date.year, date.month, date.day, 17));
    final illumination = (1 - math.cos(2 * math.pi * age / 29.530588853)) / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Notice(
          'Efemérides calculadas aproximadamente, no observaciones. Horas del Sol en Perú (UTC−5), horizonte ideal; el relieve y la atmósfera alteran el resultado. Las fases lunares usan un ciclo medio, no una efeméride de precisión.',
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) setState(() => date = d);
          },
          icon: const Icon(Icons.event),
          label: Text(dateLabel(date)),
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          minWidth: 230,
          children: [
            Metric(
              'Salida del Sol · UTC−5',
              hourLabel(solar?.sunrise),
              p == null
                  ? 'Registra las coordenadas'
                  : 'NOAA · cálculo aproximado\n${dateLabel(date)} · ${p.name}',
              Icons.wb_sunny_outlined,
            ),
            Metric(
              'Puesta del Sol · UTC−5',
              hourLabel(solar?.sunset),
              'NOAA · horizonte ideal\n${dateLabel(date)}',
              Icons.wb_twilight,
            ),
            Metric(
              'Duración del día',
              solar?.duration == null
                  ? '—'
                  : '${solar!.duration!.toStringAsFixed(2)} h',
              'Estimación astronómica\n${dateLabel(date)}',
              Icons.timelapse,
            ),
            Metric(
              'Iluminación lunar',
              '${(illumination * 100).round()} %',
              '${lunarPhase(DateTime.utc(date.year, date.month, date.day, 17))}\nCiclo medio · 12:00 Perú',
              Icons.nightlight_outlined,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Panel(
          color: forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.nightlight_round, size: 52, color: lime),
              const SizedBox(height: 16),
              Text(
                lunarPhase(DateTime.utc(date.year, date.month, date.day, 17)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Observar el cielo también forma parte de nuestra historia.',
                style: TextStyle(color: Color(0xFFD5E2CB), fontSize: 14),
              ),
              const SizedBox(height: 14),
              const Text(
                'Los calendarios lunares forman parte de saberes tradicionales. Esta aplicación no atribuye a una fase lunar un aumento demostrado de rendimiento ni la utiliza como criterio científico de siembra.',
                style: TextStyle(
                  color: Color(0xFFB7CEBB),
                  fontSize: 12,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El ritmo del año · hemisferio sur',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 14),
              Text(
                'Marzo, alrededor del 20: equinoccio de otoño.\nJunio, alrededor del 21: solsticio de invierno.\nSeptiembre, alrededor del 22: equinoccio de primavera.\nDiciembre, alrededor del 21: solsticio de verano.\n\nSon ventanas orientativas, no fechas calculadas para un año específico.\nRadiación: consulta NASA POWER; una duración del día no es una medición de radiación.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.9),
              ),
              SizedBox(height: 12),
              SelectableText(
                'Método solar: https://gml.noaa.gov/grad/solcalc/solareqns.PDF',
                style: TextStyle(color: green, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AssistantScreen extends StatefulWidget {
  final AppState state;
  const AssistantScreen({super.key, required this.state});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final input = TextEditingController();
  final messages = <({bool user, String text})>[];
  void send(String question) {
    if (question.trim().isEmpty) return;
    final answer = advise(question, widget.state.plot);
    final weather = widget.state.weather?.latest('T2M');
    final extra = weather == null
        ? '\n\nClima: no hay una serie NASA consultada en esta sesión.'
        : '\n\nContexto disponible: temperatura media regional ${weather.value!.toStringAsFixed(1)} ${weather.unit}, NASA POWER, ${dateLabel(weather.observationDate)}. Este dato histórico no es un pronóstico ni basta para determinar aptitud.';
    setState(() {
      messages.add((user: true, text: question.trim()));
      messages.add((user: false, text: '$answer$extra'));
      input.clear();
    });
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Notice(
        'Asistente de orientación basado en reglas locales y catálogo inicial. No hay un modelo de IA generativa conectado. Usa la parcela registrada y el contexto NASA consultado, explica las carencias y no prescribe fertilizantes ni tratamientos.',
      ),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: forest),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversemos sobre tu tierra.',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Orientación transparente, con el contexto de tu parcela.',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        '¿Qué puedo sembrar a mi altitud?',
                        '¿Qué sembrar después de papa?',
                        '¿Cómo ahorrar agua?',
                        '¿Cómo recuperar la fertilidad?',
                        '¿Qué cultivo es más rentable?',
                      ]
                      .map(
                        (q) => ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 11)),
                          onPressed: () => send(q),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            if (messages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 35),
                child: Center(
                  child: Text(
                    'Una buena decisión comienza con una buena pregunta.',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              ),
            ...messages.map(
              (m) => Align(
                alignment: m.user
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 760),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: m.user ? forest : cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.user ? 'TÚ' : 'TARPUY · ORIENTACIÓN POR REGLAS',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: m.user ? lime : green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      SelectableText(
                        m.text,
                        style: TextStyle(
                          color: m.user ? Colors.white : ink,
                          fontSize: 13,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1500,
                    decoration: const InputDecoration(
                      hintText: 'Pregunta sobre tu parcela…',
                    ),
                    onSubmitted: send,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Enviar pregunta',
                  onPressed: () => send(input.text),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
            if (messages.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => messages.clear()),
                child: const Text('Limpiar conversación'),
              ),
          ],
        ),
      ),
    ],
  );
}

class ImpactScreen extends StatelessWidget {
  final AppState state;
  const ImpactScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final proposed = simulate(state.rotation, state.years, cover: state.cover);
    final baseline = simulate(
      [state.rotation.first],
      state.years,
      cover: false,
    );
    final initial = state.plot?.organicMatter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Notice(
          'AGROTWINS / SOILBANK · escenario didáctico del plan guardado. No equivale a un gemelo digital calibrado, una medición de salud del suelo ni una certificación de impacto. Sin mediciones iniciales, no se dibuja una trayectoria observada.',
        ),
        Panel(
          color: forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Tag('EL CAMBIO EMPIEZA BAJO TUS PIES', color: lime),
              const SizedBox(height: 16),
              const Text(
                'Lo que siembras hoy,\ntambién cultiva el mañana.',
                style: TextStyle(
                  fontSize: 29,
                  color: Colors.white,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Plan: ${state.rotation.map((c) => c.name).join(" → ")} · ${state.years} años',
                style: const TextStyle(color: Color(0xFFCBDBC6), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ResponsiveGrid(
          minWidth: 230,
          children: [
            Metric(
              'Diversidad del escenario',
              '${proposed.diversity.round()} familias',
              'Simulado · secuencia guardada',
              Icons.spa_outlined,
            ),
            Metric(
              'Cobertura del escenario',
              '${proposed.cover.toStringAsFixed(0)} /100',
              'Índice ilustrativo · no es % medido',
              Icons.grass,
            ),
            Metric(
              'Humedad del terreno',
              'Pendiente',
              'Sin sensor ni producto SMAP conectado',
              Icons.water_drop_outlined,
            ),
            Metric(
              'Materia orgánica inicial',
              initial == null ? 'Pendiente' : '$initial %',
              initial == null
                  ? 'Requiere análisis de suelo'
                  : 'Aportada por agricultor\n${dateLabel(state.plot!.updatedAt)}',
              Icons.science_outlined,
            ),
          ],
        ),
        const SizedBox(height: 22),
        comparisonPanel(baseline, proposed),
        const SizedBox(height: 22),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cómo interpretar el escenario',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Text(
                'Cambio ilustrativo de materia orgánica: ${proposed.organicChange >= 0 ? "+" : ""}${proposed.organicChange.toStringAsFixed(2)} puntos porcentuales en ${state.years} años. No es una predicción.\n${initial == null ? "No se calcula un valor final absoluto porque falta un análisis inicial." : "Valor aritmético final: ${(initial + proposed.organicChange).clamp(0, 100).toStringAsFixed(2)} %. Es una simulación sin calibrar, no una proyección validada."}\n\nLa demanda hídrica es un índice por cultivo. No mide eficiencia de riego ni litros ahorrados.\nLa erosión compara cobertura y repetición de familias; faltan pendiente, lluvia, textura y manejo para cuantificar pérdida de suelo.\nLa salud integral del suelo y el NDVI están pendientes de análisis y conexión satelital.\nLos supuestos y fórmulas están disponibles en Simulador de rotación.',
                style: const TextStyle(color: muted, fontSize: 12, height: 1.9),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => copyText(
                  context,
                  const JsonEncoder.withIndent('  ').convert({
                    'type': 'simulado',
                    'model': 'TARPUY didáctico v1; sin calibración',
                    'generatedAt': DateTime.now().toUtc().toIso8601String(),
                    'years': state.years,
                    'crops': state.rotation.map((c) => c.name).toList(),
                    'coverAssumption': state.cover,
                    'waterIndex': proposed.waterIndex,
                    'coverIndex': proposed.cover,
                    'erosionIndex': proposed.erosionIndex,
                    'organicMatterDeltaPercentagePoints':
                        proposed.organicChange,
                    'notMeasured': ['soilMoisture', 'NDVI', 'soilHealth'],
                  }),
                ),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar informe con supuestos'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
