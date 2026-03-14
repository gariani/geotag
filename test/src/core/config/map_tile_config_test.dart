import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/core/config/map_tile_config.dart';

void main() {
  group('MapTileConfig', () {
    test('fromEnvironment returns default values when no env set', () {
      final config = MapTileConfig.fromEnvironment();
      expect(
        config.urlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
      expect(config.attributionText, '© OpenStreetMap contributors');
      expect(config.attributionUrl, 'https://www.openstreetmap.org/copyright');
      expect(config.userAgentPackageName, 'geotag');
    });

    test('creates with custom values', () {
      const config = MapTileConfig(
        urlTemplate: 'https://custom.tiles/{z}/{x}/{y}.png',
        attributionText: '© Custom',
        attributionUrl: 'https://custom.org',
        userAgentPackageName: 'myapp',
      );
      expect(config.urlTemplate, contains('custom.tiles'));
      expect(config.attributionText, '© Custom');
      expect(config.attributionUrl, 'https://custom.org');
      expect(config.userAgentPackageName, 'myapp');
    });
  });
}
