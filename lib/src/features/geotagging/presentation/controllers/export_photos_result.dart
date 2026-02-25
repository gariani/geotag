sealed class ExportPhotosResult {}

class ExportPhotosSuccess extends ExportPhotosResult {
  ExportPhotosSuccess(this.path);
  final String path;
}

class ExportPhotosNoLocation extends ExportPhotosResult {}

class ExportPhotosCancelled extends ExportPhotosResult {}
