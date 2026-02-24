import 'location_info.dart';

class Photo {
  final String id;
  final String title;
  final DateTime takenAt;
  final String? imagePath;
  final LocationInfo? location;

  const Photo({
    required this.id,
    required this.title,
    required this.takenAt,
    this.imagePath,
    this.location,
  });

  Photo copyWith({
    String? imagePath,
    LocationInfo? location,
  }) {
    return Photo(
      id: id,
      title: title,
      takenAt: takenAt,
      imagePath: imagePath ?? this.imagePath,
      location: location ?? this.location,
    );
  }
}
