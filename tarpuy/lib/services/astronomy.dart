import 'dart:math';

class SolarDay {
  final double? sunrise, sunset;
  const SolarDay(this.sunrise, this.sunset);
  double? get duration =>
      sunrise == null || sunset == null ? null : sunset! - sunrise!;
}

// NOAA fractional-year approximation, standard zenith 90.833 degrees.
SolarDay solarDay(DateTime date, double latitude, double longitude) {
  final day =
      DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).difference(DateTime.utc(date.year)).inDays +
      1;
  final days = DateTime.utc(
    date.year + 1,
  ).difference(DateTime.utc(date.year)).inDays;
  final g = 2 * pi / days * (day - 1);
  final eq =
      229.18 *
      (.000075 +
          .001868 * cos(g) -
          .032077 * sin(g) -
          .014615 * cos(2 * g) -
          .040849 * sin(2 * g));
  final decl =
      .006918 -
      .399912 * cos(g) +
      .070257 * sin(g) -
      .006758 * cos(2 * g) +
      .000907 * sin(2 * g) -
      .002697 * cos(3 * g) +
      .00148 * sin(3 * g);
  final lat = latitude * pi / 180;
  final c =
      cos(90.833 * pi / 180) / (cos(lat) * cos(decl)) - tan(lat) * tan(decl);
  if (c < -1 || c > 1) return const SolarDay(null, null);
  final ha = acos(c) * 180 / pi;
  return SolarDay(
    (720 - 4 * (longitude + ha) - eq - 300) / 60,
    (720 - 4 * (longitude - ha) - eq - 300) / 60,
  );
}

double lunarAge(DateTime date) =>
    (date.toUtc().difference(DateTime.utc(2000, 1, 6, 18, 14)).inMinutes /
        1440) %
    29.530588853;
String lunarPhase(DateTime date) {
  final age = lunarAge(date);
  return [
    'Luna nueva',
    'Creciente',
    'Cuarto creciente',
    'Gibosa creciente',
    'Luna llena',
    'Gibosa menguante',
    'Cuarto menguante',
    'Menguante',
  ][((age / 29.530588853 * 8).round()) % 8];
}

String hourLabel(double? hour) {
  if (hour == null) return 'No disponible';
  final minutes = (hour * 60).round() % 1440;
  return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
