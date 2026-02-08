import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/report_model.dart';

class ReportDatabaseService {
  static const String _databaseUrl =
      'https://saferoute-129158-default-rtdb.asia-southeast1.firebasedatabase.app/';

  ReportDatabaseService({FirebaseDatabase? database})
      : _reportsRef =
            (database ?? FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: _databaseUrl,
            ))
                .ref('reports');

  final DatabaseReference _reportsRef;

  Future<void> addReport(Report report) async {
    await _reportsRef.child(report.id).set({
      'imageUrl': report.imageUrl,
      'streetName': report.streetName,
      'note': report.note,
      'latitude': report.latitude,
      'longitude': report.longitude,
      'createdAt': report.createdAt.millisecondsSinceEpoch,
      'userId': report.userId,
    });
  }

  Stream<List<Report>> getReports() {
    return _reportsRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Report>[];

      if (data is! Map) return <Report>[];

      final reports = <Report>[];
      data.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          reports.add(_fromMap(key.toString(), map));
        }
      });

      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Future<void> deleteReport(String reportId) async {
    await _reportsRef.child(reportId).remove();
  }

  Future<Report?> getReportById(String reportId) async {
    final snapshot = await _reportsRef.child(reportId).get();
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }
    final value = snapshot.value;
    if (value is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(value);
    return _fromMap(reportId, map);
  }

  Report _fromMap(String id, Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    final createdAt = createdAtValue is int
        ? DateTime.fromMillisecondsSinceEpoch(createdAtValue)
        : DateTime.tryParse(createdAtValue?.toString() ?? '') ?? DateTime.now();

    return Report(
      id: id,
      imageUrl: (map['imageUrl'] ?? map['imagePath'])?.toString() ?? '',
      streetName: map['streetName']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      createdAt: createdAt,
      userId: map['userId']?.toString() ?? '',
    );
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
