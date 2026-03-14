import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../helpers/photo_path_helper.dart';

/// Extracts thumbnails from RAW image files using exiftool.
/// Only available on desktop (Linux, macOS, Windows) where exiftool is used.
class RawThumbnailService {
  RawThumbnailService() : _cache = {};

  static final instance = RawThumbnailService();

  final Map<String, String> _cache;
  final Map<String, Future<String?>> _futureCache = {};
  Future<bool>? _exifToolAvailable;

  static const _rawExtensions = {
    'arw', 'ARW', 'srf', 'SRF', 'sr2', 'SR2',
    'cr2', 'CR2', 'cr3', 'CR3', 'nef', 'NEF', 'nrw', 'NRW',
    'dng', 'DNG', 'orf', 'ORF', 'rw2', 'RW2', 'raf', 'RAF',
  };

  bool isRawFile(String path) {
    final name = PhotoPathHelper.fileName(path);
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return false;
    final ext = name.substring(dot + 1);
    return _rawExtensions.contains(ext);
  }

  /// Returns path to a viewable thumbnail, or null if extraction fails.
  /// For non-RAW files, returns the original path.
  /// Caches the Future so rebuilds don't restart extraction.
  Future<String?> getThumbnailPath(String imagePath) {
    if (!isRawFile(imagePath)) return Future.value(imagePath);
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return Future.value(null);
    }

    _futureCache[imagePath] ??= _extractThumbnail(imagePath);
    return _futureCache[imagePath]!;
  }

  Future<String?> _extractThumbnail(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final stat = await file.stat();
    final cacheKey = '$imagePath|${stat.modified.millisecondsSinceEpoch}';
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (await File(cached).exists()) return cached;
      _cache.remove(cacheKey);
    }

    if (!await _hasExifTool()) return null;

    final tempDir = await getTemporaryDirectory();
    final hash = imagePath.hashCode.abs().toRadixString(36);
    final outPath = PhotoPathHelper.joinPath(tempDir.path, 'geopic_thumb_$hash.jpg');

    final tags = ['-PreviewImage', '-JpgFromRaw', '-ThumbnailImage'];
    for (final tag in tags) {
      try {
        final result = await Process.run(
          'exiftool',
          ['-b', tag, imagePath],
          runInShell: false,
          stdoutEncoding: null,
        );

        if (result.exitCode == 0 && result.stdout != null) {
          final raw = result.stdout;
          final bytes = raw is List ? List<int>.from(raw) : <int>[];
          if (bytes.length > 100) {
            await File(outPath).writeAsBytes(bytes);
            _cache[cacheKey] = outPath;
            return outPath;
          }
        }
      } catch (_) {}
    }

    try {
      final result = await Process.run(
        'exiftool',
        ['-b', '-PreviewImage', '-o', outPath, imagePath],
        runInShell: false,
      );
      if (result.exitCode == 0 && await File(outPath).exists()) {
        final size = await File(outPath).length();
        if (size > 0) {
          _cache[cacheKey] = outPath;
          return outPath;
        }
      }
    } catch (_) {}

    final dcrawPath = await _extractWithDcraw(imagePath, outPath);
    if (dcrawPath != null) {
      _cache[cacheKey] = dcrawPath;
      return dcrawPath;
    }
    return null;
  }

  Future<String?> _extractWithDcraw(String imagePath, String outPath) async {
    try {
      final result = await Process.run(
        'dcraw',
        ['-e', '-c', imagePath],
        runInShell: false,
        stdoutEncoding: null,
      );
      if (result.exitCode == 0 && result.stdout != null) {
        final bytes = result.stdout;
        if (bytes is List && bytes.length > 100) {
          final dcrawOut = outPath.replaceFirst('.jpg', '_dcraw.jpg');
          await File(dcrawOut).writeAsBytes(List<int>.from(bytes));
          if (await File(dcrawOut).length() > 0) {
            return dcrawOut;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _hasExifTool() async {
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

  /// Checks availability of external tools for RAW thumbnail extraction.
  /// Use this to inform users when exiftool or dcraw are missing.
  Future<RawThumbnailDependencies> checkDependencies() async {
    final exiftool = await _probeExifTool();
    var dcraw = false;
    try {
      await Process.run('dcraw', ['-v']);
      dcraw = true;
    } catch (_) {}
    return RawThumbnailDependencies(
      exiftoolAvailable: exiftool,
      dcrawAvailable: dcraw,
    );
  }
}

/// Availability of external tools used for RAW thumbnail extraction.
class RawThumbnailDependencies {
  const RawThumbnailDependencies({
    required this.exiftoolAvailable,
    required this.dcrawAvailable,
  });

  final bool exiftoolAvailable;
  final bool dcrawAvailable;

  /// True if at least one extraction tool is available.
  bool get hasAnyExtractor => exiftoolAvailable || dcrawAvailable;

  /// Human-readable status for debugging or UI hints.
  String get statusMessage {
    if (exiftoolAvailable && dcrawAvailable) {
      return 'exiftool and dcraw available';
    }
    if (exiftoolAvailable) {
      return 'exiftool available';
    }
    if (dcrawAvailable) {
      return 'dcraw available (exiftool recommended)';
    }
    return 'Install exiftool for RAW thumbnails (e.g. pacman -S perl-image-exiftool)';
  }
}
