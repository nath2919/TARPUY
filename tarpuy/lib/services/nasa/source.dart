abstract class SatelliteSource {
  String get name;
  String get datasetId;
  String get resolution;
  String get url;
  String get description;
  bool get connected => false;
  Future<void> fetch() => Future.error(
    UnsupportedError(
      '$name: integración pendiente; requiere acceso y procesamiento Earthdata.',
    ),
  );
}
