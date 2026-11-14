import 'source.dart';

class LandsatSource extends SatelliteSource {
  @override
  String get name => 'HLS · Landsat + Sentinel-2';
  @override
  String get datasetId => 'HLSL30 / HLSS30 · v2 (referencia)';
  @override
  String get resolution => '30 m · según observación y nubosidad';
  @override
  String get url => 'https://hls.gsfc.nasa.gov/products-description/';
  @override
  String get description =>
      'Reflectancia armonizada; requiere selección de escenas y máscaras de calidad.';
}
