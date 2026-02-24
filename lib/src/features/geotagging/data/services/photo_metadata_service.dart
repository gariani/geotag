import 'dart:io';

import 'package:flutter_exif_plugin/flutter_exif_plugin.dart';

import '../../domain/entities/photo.dart';

class PhotoMetadataService {
  Future<bool>? _exifToolAvailable;

  Future<void> applyLocation(Photo photo) async {
    if (photo.imagePath == null || photo.location == null) {
      return;
    }

    if (await _writeWithFlutterExif(photo)) {
      return;
    }
    if (await _writeWithExifTool(photo)) {
      return;
    }
    await _writeXmpSidecar(photo);
  }

  Future<void> applyLocations(List<Photo> photos) async {
    for (final photo in photos) {
      await applyLocation(photo);
    }
  }

  Future<bool> _writeWithExifTool(Photo photo) async {
    if (!_isDesktopPlatform()) {
      return false;
    }

    final available = await _hasExifTool();
    if (!available) {
      return false;
    }

    final latitude = photo.location!.latitude;
    final longitude = photo.location!.longitude;
    final latRef = latitude >= 0 ? 'N' : 'S';
    final lonRef = longitude >= 0 ? 'E' : 'W';

    final result = await Process.run('exiftool', [
      '-overwrite_original',
      '-GPSLatitude=${latitude.abs()}',
      '-GPSLatitudeRef=$latRef',
      '-GPSLongitude=${longitude.abs()}',
      '-GPSLongitudeRef=$lonRef',
      photo.imagePath!,
    ]);

    return result.exitCode == 0;
  }

  Future<bool> _writeWithFlutterExif(Photo photo) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final latitude = photo.location!.latitude;
      final longitude = photo.location!.longitude;
      final exif = FlutterExif.fromPath(photo.imagePath!);
      await exif.setLatLong(latitude, longitude);
      await exif.saveAttributes();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isDesktopPlatform() {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  Future<bool> _hasExifTool() {
    _exifToolAvailable ??= _probeExifTool();
    return _exifToolAvailable!;
  }

  Future<bool> _probeExifTool() async {
    try {
      final result = await Process.run('exiftool', ['-ver']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeXmpSidecar(Photo photo) async {
    final path = photo.imagePath!;
    final xmpPath = _xmpPath(path);
    final latitude = photo.location!.latitude;
    final longitude = photo.location!.longitude;
    final latRef = latitude >= 0 ? 'N' : 'S';
    final lonRef = longitude >= 0 ? 'E' : 'W';
    final latDms = _toDms(latitude.abs());
    final lonDms = _toDms(longitude.abs());

    final content =
        '''
<?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description rdf:about=""
      xmlns:exif="http://ns.adobe.com/exif/1.0/">
      <exif:GPSLatitude>$latDms</exif:GPSLatitude>
      <exif:GPSLongitude>$lonDms</exif:GPSLongitude>
      <exif:GPSLatitudeRef>$latRef</exif:GPSLatitudeRef>
      <exif:GPSLongitudeRef>$lonRef</exif:GPSLongitudeRef>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>
''';

    await File(xmpPath).writeAsString(content);
  }

  String _xmpPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final dot = normalized.lastIndexOf('.');
    if (dot == -1) {
      return '$path.xmp';
    }
    return '${normalized.substring(0, dot)}.xmp';
  }

  String _toDms(double value) {
    final degrees = value.floor();
    final minutesFull = (value - degrees) * 60;
    final minutes = minutesFull.floor();
    final seconds = (minutesFull - minutes) * 60;
    return '$degrees,$minutes,${seconds.toStringAsFixed(3)}';
  }


}
