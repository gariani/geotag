import 'dart:io';

import 'package:flutter_exif_plugin/flutter_exif_plugin.dart';

import '../../domain/entities/location_info.dart';

/// Reads GPS location from image EXIF metadata.
/// Only supported on Android; returns null on other platforms.
class ExifReaderService {
  Future<LocationInfo?> readLocation(String imagePath) async {
    if (!Platform.isAndroid) return null;

    try {
      final exif = FlutterExif.fromPath(imagePath);
      final latLong = await exif.getLatLong();
      if (latLong == null || latLong.length < 2) return null;

      return LocationInfo(
        latitude: latLong[0],
        longitude: latLong[1],
      );
    } catch (_) {
      return null;
    }
  }
}
