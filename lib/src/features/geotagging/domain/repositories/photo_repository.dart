import '../entities/photo.dart';

abstract class PhotoRepository {
  Future<List<Photo>> fetchPhotos();
  Future<void> updatePhotos(List<Photo> photos);
  /// Updates stored photo list without writing EXIF to files.
  Future<void> persistPhotos(List<Photo> photos);
  /// Writes EXIF location data to the files at each photo's imagePath.
  Future<void> writeExifForPhotos(List<Photo> photos);
}
