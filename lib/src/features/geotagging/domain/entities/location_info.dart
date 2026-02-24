class LocationInfo {
  final double latitude;
  final double longitude;
  final String? label;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    this.label,
  });
}
