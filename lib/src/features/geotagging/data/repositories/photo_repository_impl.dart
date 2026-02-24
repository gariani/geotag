import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../services/photo_metadata_service.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({PhotoMetadataService? metadataService})
      : _metadataService = metadataService ?? PhotoMetadataService();

  final PhotoMetadataService _metadataService;
  final List<Photo> _photos = [];

  @override
  Future<List<Photo>> fetchPhotos() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<Photo>.from(_photos);
  }

  @override
  Future<void> updatePhotos(List<Photo> photos) async {
    _photos
      ..clear()
      ..addAll(photos);
    await _metadataService.applyLocations(photos);
  }
}
