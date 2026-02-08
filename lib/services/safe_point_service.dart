import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/safe_point_model.dart';

class SafePointService {
  Future<List<SafePoint>> fetchSafePoints() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/users');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => SafePoint.fromJson(e)).toList();
      }

      return _dummySafePoints();
    } catch (_) {
      return _dummySafePoints();
    }
  }

  List<SafePoint> _dummySafePoints() {
    return const [
      SafePoint(id: 1, name: 'Pos Polisi Sudirman', email: 'sudirman@safe.id'),
      SafePoint(id: 2, name: 'Pos Taman Kota', email: 'tamankota@safe.id'),
      SafePoint(id: 3, name: 'Pos Kampus Utama', email: 'kampus@safe.id'),
      SafePoint(id: 4, name: 'Pos Stasiun', email: 'stasiun@safe.id'),
    ];
  }
}
