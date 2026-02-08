class Report {
  final String id;
  final String imageUrl;
  final String streetName;
  final String note;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String userId;

  Report({
    required this.id,
    required this.imageUrl,
    this.streetName = '',
    this.note = '',
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.userId,
  });
}
