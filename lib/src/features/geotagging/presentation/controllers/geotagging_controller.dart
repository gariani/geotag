import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/helpers/photo_path_helper.dart';
import '../../data/services/exif_reader_service.dart';
import '../../data/services/osm_geocoding_service.dart';
import '../../domain/entities/location_info.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import 'export_photos_result.dart';
import 'photo_filter.dart';

class GeotaggingController extends ChangeNotifier {
  GeotaggingController(this._repository)
    : _exifReader = ExifReaderService(),
      _geocoding = OsmGeocodingService() {
    _loadPhotos();
  }

  final PhotoRepository _repository;
  final ExifReaderService _exifReader;
  final OsmGeocodingService _geocoding;
  static const String _userAgent = 'geotag/1.0';
  final Set<String> _selectedPhotoIds = {};
  List<Photo> _photos = [];
  LocationInfo? _selectedLocation;
  bool _isLoading = false;
  bool _hasCompletedInitialLoad = false;
  bool _permissionRequested = false;
  PhotoFilter _filter = PhotoFilter.all;
  bool _isMultiSelectEnabled = false;

  List<Photo> get photos => _filteredPhotos;
  PhotoFilter get filter => _filter;
  List<Photo> get allPhotos => _photos;
  bool get isMultiSelectEnabled => _isMultiSelectEnabled;

  List<Photo> get _filteredPhotos {
    switch (_filter) {
      case PhotoFilter.all:
        return _photos;
      case PhotoFilter.missingLocation:
        return _photos.where((p) => p.location == null).toList();
      case PhotoFilter.recent:
        final sorted = List<Photo>.from(_photos)
          ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
        return sorted.take(50).toList();
    }
  }

  void setFilter(PhotoFilter value) {
    _filter = value;
    notifyListeners();
  }

  void toggleMultiSelectMode() {
    _isMultiSelectEnabled = !_isMultiSelectEnabled;
    if (!_isMultiSelectEnabled && _selectedPhotoIds.length > 1) {
      // When leaving bulk mode, keep at most one selection for simpler tagging.
      final first = _selectedPhotoIds.isNotEmpty
          ? _selectedPhotoIds.first
          : null;
      _selectedPhotoIds.clear();
      if (first != null) {
        _selectedPhotoIds.add(first);
      }
    }
    notifyListeners();
  }

  Set<String> get selectedPhotoIds => _selectedPhotoIds;
  LocationInfo? get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  bool get hasCompletedInitialLoad => _hasCompletedInitialLoad;

  Future<void> _loadPhotos() async {
    _isLoading = true;
    notifyListeners();

    _photos = await _repository.fetchPhotos();
    _isLoading = false;
    _hasCompletedInitialLoad = true;
    notifyListeners();
  }

  void togglePhotoSelection(String photoId) {
    if (_isMultiSelectEnabled) {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
      } else {
        _selectedPhotoIds.add(photoId);
      }
    } else {
      if (_selectedPhotoIds.length == 1 &&
          _selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.clear();
      } else {
        _selectedPhotoIds
          ..clear()
          ..add(photoId);
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPhotoIds.clear();
    notifyListeners();
  }

  void setLocation(LocationInfo location) {
    _selectedLocation = location;
    notifyListeners();
  }

  /// Pre-fill the pin from the first selected photo's existing location (EXIF).
  /// Call when switching to Map tab with photos selected.
  Future<void> prefillLocationFromSelection() async {
    if (_selectedPhotoIds.isEmpty) return;

    final withLocation = _photos
        .where((p) => _selectedPhotoIds.contains(p.id) && p.location != null)
        .toList();
    if (withLocation.isEmpty) return;
    final firstWithLocation = withLocation.first;
    var loc = firstWithLocation.location!;
    if (loc.label == null || loc.label!.isEmpty) {
      final label = await _geocoding.reverseGeocode(
        loc.latitude,
        loc.longitude,
        _userAgent,
      );
      if (label != null) {
        loc = LocationInfo(
          latitude: loc.latitude,
          longitude: loc.longitude,
          label: label,
        );
      }
    }
    _selectedLocation = loc;
    notifyListeners();
  }

  Future<void> importPhotos() async {
    try {
      final paths = await _pickPhotoPaths();
      if (paths.isEmpty) {
        return;
      }

      _isLoading = true;
      notifyListeners();

      final newPhotos = <Photo>[];
      for (final path in paths) {
        final lastModified = await _lastModifiedOrNow(path);
        final location = await _exifReader.readLocation(path);
        newPhotos.add(
          Photo(
            id: 'p${DateTime.now().microsecondsSinceEpoch}-${newPhotos.length}',
            title: PhotoPathHelper.fileName(path),
            takenAt: lastModified,
            imagePath: path,
            location: location,
          ),
        );
      }

      _photos = [..._photos, ...newPhotos];
      await _repository.updatePhotos(_photos);
      _isLoading = false;
      notifyListeners();
    } on MissingPluginException catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Photo picker plugin missing: $error');
    } on PlatformException catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Photo picker failed: $error');
    }
  }

  Future<List<String>> _pickPhotoPaths() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      return images.map((file) => file.path).toList();
    }

    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    return files.map((file) => file.path).toList();
  }

  Future<DateTime> _lastModifiedOrNow(String path) async {
    try {
      final stat = await File(path).stat();
      return stat.modified;
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Applies location to selected photos in memory only. Does not write to files.
  /// Use Export or Apply & Export Copies to save to disk.
  Future<bool> applyLocationToSelection() async {
    if (_selectedLocation == null || _selectedPhotoIds.isEmpty) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final selectedIds = Set<String>.from(_selectedPhotoIds);
    final updated = _photos
        .map(
          (photo) => selectedIds.contains(photo.id)
              ? photo.copyWith(location: _selectedLocation)
              : photo,
        )
        .toList();

    _photos = updated;
    await _repository.persistPhotos(updated);

    _selectedPhotoIds.clear();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Applies location to selected photos and exports to GeoTag folder.
  /// Returns the export path, or null on failure.
  Future<String?> applyLocationAndExport() async {
    if (_selectedLocation == null || _selectedPhotoIds.isEmpty) {
      return null;
    }

    final allowed = await _ensureStoragePermission();
    if (!allowed) {
      return null;
    }

    final exportDirectory = await _defaultGeoTagDirectory();
    if (exportDirectory == null) {
      return null;
    }

    _isLoading = true;
    notifyListeners();

    final selectedIds = Set<String>.from(_selectedPhotoIds);
    final updated = _photos
        .map(
          (photo) => selectedIds.contains(photo.id)
              ? photo.copyWith(location: _selectedLocation)
              : photo,
        )
        .toList();

    _photos = updated;
    await _repository.persistPhotos(updated);
    await _exportPhotos(exportDirectory, updated, selectedIds);
    _selectedPhotoIds.clear();
    _isLoading = false;
    notifyListeners();
    return exportDirectory;
  }

  /// Whether at least one selected photo has location set.
  bool get hasSelectedPhotosWithLocation => _photos.any(
    (p) => _selectedPhotoIds.contains(p.id) && p.location != null,
  );

  /// Exports only selected photos that already have location set.
  /// Does not open the map or ask for location input. Saves to GeoTag folder.
  Future<ExportPhotosResult> exportPhotosWithExistingLocation() async {
    final withLocation = _photos
        .where((p) => _selectedPhotoIds.contains(p.id) && p.location != null)
        .toList();
    if (withLocation.isEmpty) {
      return ExportPhotosNoLocation();
    }

    final allowed = await _ensureStoragePermission();
    if (!allowed) {
      return ExportPhotosCancelled();
    }

    final exportDirectory = await _defaultGeoTagDirectory();
    if (exportDirectory == null) {
      return ExportPhotosCancelled();
    }

    _isLoading = true;
    notifyListeners();

    final ids = withLocation.map((p) => p.id).toSet();
    await _exportPhotos(exportDirectory, _photos, ids);

    _selectedPhotoIds.clear();
    _isLoading = false;
    notifyListeners();
    return ExportPhotosSuccess(exportDirectory);
  }

  Future<String?> _defaultGeoTagDirectory() async {
    try {
      String? basePath;
      if (Platform.isAndroid) {
        basePath = await _getAndroidPublicPicturesPath();
      }
      if (basePath == null || basePath.isEmpty) {
        final base =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        basePath = base.path;
      }
      final geoTagDir = Directory(PhotoPathHelper.joinPath(basePath, 'GeoTag'));
      if (!await geoTagDir.exists()) {
        await geoTagDir.create(recursive: true);
      }
      return geoTagDir.path;
    } catch (_) {
      return null;
    }
  }

  static const _channel = MethodChannel('geopic/storage');

  Future<String?> _getAndroidPublicPicturesPath() async {
    try {
      final path = await _channel.invokeMethod<String>('getPublicPicturesPath');
      return path;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    if (_permissionRequested) {
      return _hasStoragePermission();
    }

    _permissionRequested = true;
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }

    final photosStatus = await Permission.photos.request();
    return photosStatus.isGranted;
  }

  Future<bool> _hasStoragePermission() async {
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      return true;
    }
    final photosStatus = await Permission.photos.status;
    return photosStatus.isGranted;
  }

  Future<void> _exportPhotos(
    String directory,
    List<Photo> photos,
    Set<String> selectedIds,
  ) async {
    final photosToExport = <Photo>[];
    for (final photo in photos) {
      if (!selectedIds.contains(photo.id) || photo.location == null) {
        continue;
      }
      final sourcePath = photo.imagePath;
      if (sourcePath == null) {
        continue;
      }
      photosToExport.add(photo);
    }

    if (photosToExport.isEmpty) {
      return;
    }

    // Copy first, then write EXIF to the copies. We write to the destination
    // (GeoTag) which we control and have write access. Writing to the source
    // often fails on mobile (gallery paths may be read-only or content URIs).
    final copiesForExif = <Photo>[];
    for (final photo in photosToExport) {
      final sourcePath = photo.imagePath!;
      final fileName = PhotoPathHelper.fileName(sourcePath);
      final destinationPath = await PhotoPathHelper.uniqueDestinationPath(
        directory,
        fileName,
      );
      await File(sourcePath).copy(destinationPath);
      copiesForExif.add(Photo(
        id: photo.id,
        title: photo.title,
        takenAt: photo.takenAt,
        imagePath: destinationPath,
        location: photo.location,
      ));
    }
    await _repository.writeExifForPhotos(copiesForExif);
  }
}
