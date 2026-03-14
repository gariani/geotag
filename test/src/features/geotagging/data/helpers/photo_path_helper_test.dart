import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/data/helpers/photo_path_helper.dart';

void main() {
  group('PhotoPathHelper', () {
    group('fileName', () {
      test('extracts filename from path with forward slashes', () {
        expect(
          PhotoPathHelper.fileName('/home/user/photos/image.jpg'),
          'image.jpg',
        );
      });

      test('extracts filename from path with backslashes on Windows', () {
        expect(
          PhotoPathHelper.fileName(r'C:\Users\photos\image.jpg'),
          'image.jpg',
        );
      });

      test('returns full string when no directory separator', () {
        expect(PhotoPathHelper.fileName('image.jpg'), 'image.jpg');
      });

      test('handles path ending with slash', () {
        expect(
          PhotoPathHelper.fileName('/folder/'),
          '/folder/',
        );
      });
    });

    group('joinPath', () {
      test('joins directory and file with separator', () {
        final result = PhotoPathHelper.joinPath('/tmp', 'photo.jpg');
        expect(result, contains('photo.jpg'));
        expect(result.endsWith('photo.jpg'), isTrue);
      });

      test('handles directory already ending with separator', () {
        final dir = '/tmp${Platform.pathSeparator}';
        final result = PhotoPathHelper.joinPath(dir, 'photo.jpg');
        expect(result, '${dir}photo.jpg');
      });
    });

    group('uniqueDestinationPath', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('photo_path_helper_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('returns same path when file does not exist', () async {
        final baseName = 'unique_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = await PhotoPathHelper.uniqueDestinationPath(
          tempDir.path,
          baseName,
        );
        expect(path, contains(baseName));
        expect(await File(path).exists(), isFalse);
      });

      test('returns path with (1) when file already exists', () async {
        final baseName = 'conflict_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final originalPath = PhotoPathHelper.joinPath(tempDir.path, baseName);
        await File(originalPath).writeAsString('content');

        final uniquePath = await PhotoPathHelper.uniqueDestinationPath(
          tempDir.path,
          baseName,
        );

        expect(uniquePath, isNot(originalPath));
        expect(uniquePath, contains('(1)'));
        expect(await File(uniquePath).exists(), isFalse);
      });

      test('increments index when (1) also exists', () async {
        final baseName = 'multi_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final dotIdx = baseName.indexOf('.');
        final name = dotIdx >= 0 ? baseName.substring(0, dotIdx) : baseName;
        final ext = dotIdx >= 0 ? baseName.substring(dotIdx) : '';
        final path1 = PhotoPathHelper.joinPath(tempDir.path, '$name (1)$ext');
        await File(path1).writeAsString('1');

        final originalPath = PhotoPathHelper.joinPath(tempDir.path, baseName);
        await File(originalPath).writeAsString('0');

        final uniquePath = await PhotoPathHelper.uniqueDestinationPath(
          tempDir.path,
          baseName,
        );

        expect(uniquePath, contains('(2)'));
        expect(await File(uniquePath).exists(), isFalse);
      });
    });
  });
}
