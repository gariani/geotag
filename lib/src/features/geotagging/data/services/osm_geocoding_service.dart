import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class OsmGeocodingService {
  Future<List<GeocodingResult>> search(String query, String userAgent) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'json',
      'limit': '5',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': userAgent,
        'Accept-Language': 'en',
      },
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            return null;
          }
          final displayName = item['display_name'];
          final latText = item['lat'];
          final lonText = item['lon'];
          if (displayName is! String || latText is! String || lonText is! String) {
            return null;
          }
          final latitude = double.tryParse(latText);
          final longitude = double.tryParse(lonText);
          if (latitude == null || longitude == null) {
            return null;
          }
          return GeocodingResult(
            displayName: displayName,
            latitude: latitude,
            longitude: longitude,
          );
        })
        .whereType<GeocodingResult>()
        .toList();
  }

  /// Reverse geocode: coordinates → place name
  Future<String?> reverseGeocode(
    double latitude,
    double longitude,
    String userAgent,
  ) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': userAgent,
        'Accept-Language': 'en',
      },
    );

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final displayName = decoded['display_name'];
    return displayName is String ? displayName : null;
  }
}
