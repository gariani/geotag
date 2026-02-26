import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../services/photo_metadata_service.dart';

/// Set to a positive duration to delay init for testing the splash screen.
/// Set to Duration.zero for production.
const _testInitDelay = Duration(seconds: 3);

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({PhotoMetadataService? metadataService})
      : _metadataService = metadataService ?? PhotoMetadataService();

  final PhotoMetadataService _metadataService;
  final List<Photo> _photos = [];

  @override
  Future<List<Photo>> fetchPhotos() async {
    await Future<void>.delayed(_testInitDelay);
    return List<Photo>.from(_photos);
  }

  @override
  Future<void> updatePhotos(List<Photo> photos) async {
    _photos
      ..clear()
      ..addAll(photos);
    await _metadataService.applyLocations(photos);
  }

  @override
  Future<void> persistPhotos(List<Photo> photos) async {
    _photos
      ..clear()
      ..addAll(photos);
  }

  @override
  Future<void> writeExifForPhotos(List<Photo> photos) async {
    await _metadataService.applyLocations(photos);
  }
}
