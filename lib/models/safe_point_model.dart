class SafePoint {
  final int id;
  final String name;
  final String email; // kita anggap alamat/kontak dummy

  const SafePoint({
    required this.id,
    required this.name,
    required this.email,
  });

  factory SafePoint.fromJson(Map<String, dynamic> json) {
    return SafePoint(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}
