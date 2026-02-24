class MapTileConfig {
  final String urlTemplate;
  final String attributionText;
  final String attributionUrl;
  final String userAgentPackageName;

  const MapTileConfig({
    required this.urlTemplate,
    required this.attributionText,
    required this.attributionUrl,
    required this.userAgentPackageName,
  });

  factory MapTileConfig.fromEnvironment() {
    return MapTileConfig(
      urlTemplate: const String.fromEnvironment(
        'MAP_TILE_URL',
        defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
      attributionText: const String.fromEnvironment(
        'MAP_ATTRIBUTION_TEXT',
        defaultValue: '© OpenStreetMap contributors',
      ),
      attributionUrl: const String.fromEnvironment(
        'MAP_ATTRIBUTION_URL',
        defaultValue: 'https://www.openstreetmap.org/copyright',
      ),
      userAgentPackageName: const String.fromEnvironment(
        'MAP_USER_AGENT',
        defaultValue: 'geotag',
      ),
    );
  }
}
