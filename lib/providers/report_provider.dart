import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ReportProvider extends ChangeNotifier {
  final List<Report> _reports = [];

  List<Report> get reports => _reports;

  void addReport(Report report) {
    _reports.insert(0, report); // laporan terbaru di atas
    notifyListeners();
  }

  void removeReport(String id) {
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
  