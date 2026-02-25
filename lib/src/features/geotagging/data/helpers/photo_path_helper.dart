import 'dart:io';

class PhotoPathHelper {
  static String fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash == -1 || lastSlash == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(lastSlash + 1);
  }

  static String joinPath(String dir, String file) {
    final separator = Platform.pathSeparator;
    if (dir.endsWith(separator)) {
      return '$dir$file';
    }
    return '$dir$separator$file';
  }

  static Future<String> uniqueDestinationPath(
    String directory,
    String fileName,
  ) async {
    final base = joinPath(directory, fileName);
    if (!await File(base).exists()) {
      return base;
    }

    final normalized = fileName.replaceAll('\\', '/');
    final dot = normalized.lastIndexOf('.');
    final name = dot == -1 ? normalized : normalized.substring(0, dot);
    final ext = dot == -1 ? '' : normalized.substring(dot);

    var index = 1;
    while (true) {
      final candidate = joinPath(directory, '$name ($index)$ext');
      if (!await File(candidate).exists()) {
        return candidate;
      }
      index += 1;
    }
  }
}
