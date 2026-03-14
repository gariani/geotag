import 'location_info.dart';

class Photo {
  final String id;
  final String title;
  final DateTime takenAt;
  final String? imagePath;
  final LocationInfo? location;
  final DateTime? exportedAt;

  const Photo({
    required this.id,
    required this.title,
    required this.takenAt,
    this.imagePath,
    this.location,
    this.exportedAt,
  });

  Photo copyWith({
    String? imagePath,
    LocationInfo? location,
    DateTime? exportedAt,
  }) {
    return Photo(
      id: id,
      title: title,
      takenAt: takenAt,
      imagePath: imagePath ?? this.imagePath,
      location: location ?? this.location,
      exportedAt: exportedAt ?? this.exportedAt,
    );
  }
}
