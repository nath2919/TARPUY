import 'source.dart';

class GpmSource extends SatelliteSource {
  @override
  String get name => 'GPM IMERG';
  @override
  String get datasetId => 'IMERG · verificar colección al integrar';
  @override
  String get resolution => '0,1° · depende del producto';
  @override
  String get url => 'https://gpm.nasa.gov/data/imerg';
  @override
  String get description =>
      'Estimaciones de precipitación multisatélite; integración pendiente.';
}
