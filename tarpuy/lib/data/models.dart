import 'dart:convert';

String dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String apiDate(DateTime date) =>
    '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

class Plot {
  final String name,
      department,
      province,
      district,
      soil,
      water,
      previous,
      priority;
  final double latitude, longitude, area;
  final double? altitude, ph, organicMatter;
  final DateTime updatedAt;
  const Plot({
    required this.name,
    required this.department,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.area,
    this.altitude,
    this.ph,
    this.organicMatter,
    this.soil = 'Sin análisis',
    this.water = 'Secano',
    this.previous = 'Sin registro',
    this.priority = 'Regenerar el suelo',
    required this.updatedAt,
  });
  String get region {
    final h = altitude;
    if (h == null) return 'Altitud pendiente · región sin determinar';
    if (h < 500) return 'Chala / Omagua: confirmar vertiente';
    if (h < 1000) return 'Yunga / Rupa-rupa: confirmar vertiente';
    if (h < 2300) return 'Yunga · clasificación altitudinal orientativa';
    if (h < 3500) return 'Quechua · Sierra';
    if (h < 4000) return 'Suni · Sierra';
    if (h < 4800) return 'Puna · Sierra';
    return 'Janca · alta montaña';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'department': department,
    'province': province,
    'district': district,
    'latitude': latitude,
    'longitude': longitude,
    'area': area,
    'altitude': altitude,
    'ph': ph,
    'organicMatter': organicMatter,
    'soil': soil,
    'water': water,
    'previous': previous,
    'priority': priority,
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory Plot.fromJson(Map<String, dynamic> j) => Plot(
    name: j['name'],
    department: j['department'],
    province: j['province'],
    district: j['district'],
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    area: (j['area'] as num).toDouble(),
    altitude: (j['altitude'] as num?)?.toDouble(),
    ph: (j['ph'] as num?)?.toDouble(),
    organicMatter: (j['organicMatter'] as num?)?.toDouble(),
    soil: j['soil'],
    water: j['water'],
    previous: j['previous'],
    priority: j['priority'],
    updatedAt: DateTime.parse(j['updatedAt']),
  );
  String encode() => jsonEncode(toJson());
}

class Crop {
  final String name, family, water, nutrition, roots;
  final int minAltitude, maxAltitude, days;
  final bool legume;
  const Crop(
    this.name,
    this.family,
    this.minAltitude,
    this.maxAltitude,
    this.days,
    this.water,
    this.nutrition,
    this.roots, {
    this.legume = false,
  });
  bool fits(Plot p) =>
      p.altitude != null &&
      p.altitude! >= minAltitude &&
      p.altitude! <= maxAltitude;
}

const crops = [
  Crop('Papa', 'Solanáceas', 1500, 4200, 150, 'Media', 'Alta', 'Superficial'),
  Crop('Quinua', 'Amarantáceas', 0, 4000, 150, 'Baja', 'Media', 'Profunda'),
  Crop(
    'Haba',
    'Fabáceas',
    2000,
    3800,
    180,
    'Media',
    'Media',
    'Media',
    legume: true,
  ),
  Crop('Maíz', 'Poáceas', 0, 3300, 180, 'Alta', 'Alta', 'Profunda'),
  Crop(
    'Tarwi',
    'Fabáceas',
    2000,
    4000,
    210,
    'Baja',
    'Baja',
    'Profunda',
    legume: true,
  ),
  Crop(
    'Frijol',
    'Fabáceas',
    0,
    2500,
    100,
    'Media',
    'Media',
    'Media',
    legume: true,
  ),
  Crop('Camote', 'Convolvuláceas', 0, 2000, 120, 'Media', 'Media', 'Media'),
  Crop(
    'Avena de cobertura',
    'Poáceas',
    2000,
    4200,
    120,
    'Media',
    'Media',
    'Fibrosa',
  ),
];

class Simulation {
  final double diversity, waterIndex, cover, erosionIndex, organicChange;
  final int legumes, familyRepeats;
  const Simulation(
    this.diversity,
    this.waterIndex,
    this.cover,
    this.erosionIndex,
    this.organicChange,
    this.legumes,
    this.familyRepeats,
  );
}

Simulation simulate(List<Crop> sequence, int years, {bool cover = true}) {
  if (sequence.isEmpty || ![3, 5, 10].contains(years)) {
    throw ArgumentError('Selecciona cultivos y un horizonte válido');
  }
  final plan = List.generate(years, (i) => sequence[i % sequence.length]);
  final families = plan.map((c) => c.family).toSet().length;
  final legumes = plan.where((c) => c.legume).length;
  final repeats = List.generate(
    years - 1,
    (i) => plan[i].family == plan[i + 1].family ? 1 : 0,
  ).fold(0, (a, b) => a + b);
  final water =
      plan
          .map(
            (c) => c.water == 'Alta'
                ? 90.0
                : c.water == 'Media'
                ? 60.0
                : 35.0,
          )
          .reduce((a, b) => a + b) /
      years;
  final coverage = (cover ? 75.0 : 35.0) + 10 * legumes / years;
  return Simulation(
    families.toDouble(),
    water,
    coverage,
    (100 - coverage + repeats * 4).clamp(0, 100).toDouble(),
    ((cover ? .04 : -.02) * years + .03 * legumes - .015 * repeats),
    legumes,
    repeats,
  );
}

List<int> sowingMonths(Plot plot) {
  if (plot.water == 'Riego permanente') return List.generate(12, (i) => i + 1);
  if (plot.altitude == null) return [];
  if (plot.altitude! >= 2000) return [9, 10, 11, 12];
  return [10, 11, 12, 1, 2, 3];
}

String advise(String question, Plot? plot) {
  if (plot == null) {
    return 'Registra primero tu parcela en Mi terreno. Necesito altitud, disponibilidad de agua y cultivos anteriores para orientar una propuesta.';
  }
  final q = question.toLowerCase();
  final context =
      'Para ${plot.name}, con ${plot.altitude?.round().toString() ?? "altitud pendiente"} m y ${plot.water.toLowerCase()}: ';
  if (q.contains('precio') || q.contains('econ') || q.contains('rentab')) {
    return '${context}no hay precios de mercado conectados. En Economía puedes introducir cotizaciones y costos propios; el margen es un escenario, no un pronóstico de venta.';
  }
  if (q.contains('agua') || q.contains('riego')) {
    return '${context}evalúa cobertura orgánica, revisión de fugas y riego localizado si tus recursos lo permiten. Antes de definir una dosis de riego se necesitan textura, humedad medida y etapa del cultivo. POWER aporta clima regional, no humedad exacta de la parcela.';
  }
  if (q.contains('papa') || q.contains('rotaci')) {
    return '${context}tras papa, considera una leguminosa adaptada (haba o tarwi en altura; frijol en zonas cálidas) y luego una familia distinta. La fijación potencial de nitrógeno depende de nodulación, manejo y residuos; no equivale a una dosis de fertilizante. Comprueba adaptación local, sanidad y análisis de suelo antes de sembrar.';
  }
  if (q.contains('fertil') || q.contains('suelo')) {
    return '${context}solicita análisis de pH, materia orgánica y nutrientes. Considera compost maduro, cobertura y rotación diversa. No puedo inferir fertilidad química desde NASA ni recomendar una dosis sin análisis.';
  }
  final suitable = crops
      .where((c) => c.fits(plot))
      .map((c) => c.name)
      .join(', ');
  return '$context${suitable.isEmpty ? "falta altitud para filtrar el catálogo" : "el catálogo orientativo incluye $suitable"}. La selección usa rangos amplios de altitud, no un modelo de aptitud validado. Confirma variedad, temperatura, agua y calendario con asistencia agronómica local. Fuente: catálogo inicial TARPUY, pendiente de validación regional.';
}
