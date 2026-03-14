import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/data/services/raw_thumbnail_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('RawThumbnailService', () {
    late RawThumbnailService service;

    setUp(() {
      service = RawThumbnailService();
    });

    group('isRawFile', () {
      test('returns true for Sony RAW extensions', () {
        expect(service.isRawFile('/path/to/photo.arw'), isTrue);
        expect(service.isRawFile('/path/to/photo.ARW'), isTrue);
        expect(service.isRawFile('/path/to/photo.srf'), isTrue);
        expect(service.isRawFile('/path/to/photo.SRF'), isTrue);
        expect(service.isRawFile('/path/to/photo.sr2'), isTrue);
        expect(service.isRawFile('/path/to/photo.SR2'), isTrue);
      });

      test('returns true for other RAW extensions', () {
        expect(service.isRawFile('/a/b.cr2'), isTrue);
        expect(service.isRawFile('/a/b.CR3'), isTrue);
        expect(service.isRawFile('/a/b.nef'), isTrue);
        expect(service.isRawFile('/a/b.DNG'), isTrue);
        expect(service.isRawFile('/a/b.orf'), isTrue);
        expect(service.isRawFile('/a/b.rw2'), isTrue);
        expect(service.isRawFile('/a/b.raf'), isTrue);
      });

      test('returns false for JPEG and PNG', () {
        expect(service.isRawFile('/path/to/photo.jpg'), isFalse);
        expect(service.isRawFile('/path/to/photo.JPG'), isFalse);
        expect(service.isRawFile('/path/to/photo.jpeg'), isFalse);
        expect(service.isRawFile('/path/to/photo.png'), isFalse);
      });

      test('returns false for path without extension', () {
        expect(service.isRawFile('/path/to/noext'), isFalse);
        expect(service.isRawFile('noext'), isFalse);
      });

      test('returns false for extension only (dot at end)', () {
        expect(service.isRawFile('/path/to/file.'), isFalse);
      });

      test('handles Windows-style paths', () {
        expect(
          service.isRawFile(r'C:\Users\Photos\image.arw'),
          isTrue,
        );
      });
    });

    group('getThumbnailPath', () {
      test('returns same path for non-RAW files', () async {
        const path = '/some/path/photo.jpg';
        final result = await service.getThumbnailPath(path);
        expect(result, path);
      });

      test('returns null for non-existent RAW file', () async {
        final path = '/nonexistent/path/photo_${DateTime.now().millisecondsSinceEpoch}.arw';
        final result = await service.getThumbnailPath(path);
        expect(result, isNull);
      });

    });

    group('checkDependencies', () {
      test('returns RawThumbnailDependencies with booleans', () async {
        final deps = await service.checkDependencies();
        expect(deps, isA<RawThumbnailDependencies>());
        expect(deps.exiftoolAvailable, isA<bool>());
        expect(deps.dcrawAvailable, isA<bool>());
      });

      test('hasAnyExtractor is true when exiftool or dcraw available', () async {
        final deps = await service.checkDependencies();
        expect(
          deps.hasAnyExtractor,
          deps.exiftoolAvailable || deps.dcrawAvailable,
        );
      });

      test('statusMessage is non-empty', () async {
        final deps = await service.checkDependencies();
        expect(deps.statusMessage, isNotEmpty);
      });
    });

  });

  group('RawThumbnailDependencies', () {
    test('statusMessage when both available', () {
      const deps = RawThumbnailDependencies(
        exiftoolAvailable: true,
        dcrawAvailable: true,
      );
      expect(deps.statusMessage, contains('exiftool'));
      expect(deps.statusMessage, contains('dcraw'));
    });

    test('statusMessage when only exiftool', () {
      const deps = RawThumbnailDependencies(
        exiftoolAvailable: true,
        dcrawAvailable: false,
      );
      expect(deps.statusMessage, contains('exiftool'));
    });

    test('statusMessage when only dcraw', () {
      const deps = RawThumbnailDependencies(
        exiftoolAvailable: false,
        dcrawAvailable: true,
      );
      expect(deps.statusMessage, contains('dcraw'));
    });

    test('statusMessage when neither available', () {
      const deps = RawThumbnailDependencies(
        exiftoolAvailable: false,
        dcrawAvailable: false,
      );
      expect(deps.statusMessage, contains('Install exiftool'));
    });
  });
}
