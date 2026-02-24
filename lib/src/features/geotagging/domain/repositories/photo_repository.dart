import '../entities/photo.dart';

abstract class PhotoRepository {
  Future<List<Photo>> fetchPhotos();
  Future<void> updatePhotos(List<Photo> photos);
}
