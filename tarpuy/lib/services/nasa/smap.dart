import 'source.dart';

class SmapSource extends SatelliteSource {
  @override
  String get name => 'SMAP';
  @override
  String get datasetId => 'SPL3SMP_E · v6 (referencia)';
  @override
  String get resolution => 'Cuadrícula de 9 km · diaria';
  @override
  String get url => 'https://nsidc.org/data/spl3smp_e/versions/6';
  @override
  String get description =>
      'Humedad superficial regional. No mide directamente la humedad de un huerto.';
}
