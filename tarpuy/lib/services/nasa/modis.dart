import 'source.dart';

class ModisSource extends SatelliteSource {
  @override
  String get name => 'MODIS';
  @override
  String get datasetId => 'MOD13Q1 · v061 (referencia)';
  @override
  String get resolution => '250 m · compuesto de 16 días';
  @override
  String get url => 'https://lpdaac.usgs.gov/products/mod13q1v061/';
  @override
  String get description =>
      'Índices NDVI/EVI para seguimiento de vegetación; sin observaciones cargadas.';
}
