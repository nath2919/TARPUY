import 'package:flutter_test/flutter_test.dart';
import 'package:tarpuy/data/models.dart';
import 'package:tarpuy/services/astronomy.dart';

Plot plot({double? altitude = 3200, String water = 'Secano'}) => Plot(
  name: 'Parcela de prueba',
  department: 'Cusco',
  province: 'Cusco',
  district: 'San Jerónimo',
  latitude: -13.5,
  longitude: -71.9,
  area: 1,
  altitude: altitude,
  water: water,
  updatedAt: DateTime.utc(2025),
);
void main() {
  test('No infiere pH, altitud ni materia orgánica de las coordenadas', () {
    final p = plot(altitude: null);
    expect(p.ph, isNull);
    expect(p.organicMatter, isNull);
    expect(p.region, contains('pendiente'));
    expect(sowingMonths(p), isEmpty);
    expect(Plot.fromJson(p.toJson()).latitude, p.latitude);
  });
  test('Calendario responde a agua y altitud, sin ventana universal', () {
    expect(sowingMonths(plot()), [9, 10, 11, 12]);
    expect(sowingMonths(plot(altitude: 100)), [10, 11, 12, 1, 2, 3]);
    expect(sowingMonths(plot(water: 'Riego permanente')), hasLength(12));
    expect(crops.firstWhere((c) => c.name == 'Camote').fits(plot()), isFalse);
  });
  test('Rotación compara monocultivo, familias y leguminosas', () {
    final mono = simulate([crops[0]], 5, cover: false);
    final diverse = simulate([crops[0], crops[2], crops[1]], 5);
    expect(mono.familyRepeats, 4);
    expect(diverse.familyRepeats, 0);
    expect(diverse.legumes, 2);
    expect(diverse.diversity, 3);
    expect(diverse.erosionIndex, lessThan(mono.erosionIndex));
    expect(
      simulate([crops[2]], 10).organicChange,
      greaterThan(simulate([crops[2]], 3).organicChange),
    );
    expect(() => simulate([], 5), throwsArgumentError);
  });
  test('Asistente reconoce datos ausentes y ausencia de precios', () {
    expect(advise('Qué sembrar', null), contains('Registra primero'));
    expect(advise('precio', plot()), contains('no hay precios'));
    expect(advise('fertilidad', plot()), contains('análisis'));
    expect(advise('después de papa', plot()), contains('leguminosa'));
  });
  test('Salida y puesta NOAA son plausibles y dependen de coordenadas', () {
    final lima = solarDay(DateTime(2025, 3, 20), -12.08, -76.95);
    expect(lima.sunrise, inInclusiveRange(5.5, 6.6));
    expect(lima.sunset, inInclusiveRange(17.5, 18.7));
    expect(lima.duration, inInclusiveRange(11.8, 12.4));
    expect(solarDay(DateTime(2025, 6, 21), 90, 0).sunrise, isNull);
    expect(lunarAge(DateTime.utc(2000, 1, 6, 18, 14)), closeTo(0, .001));
    expect(hourLabel(5.999), '06:00');
  });
}
