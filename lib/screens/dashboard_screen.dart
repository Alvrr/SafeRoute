import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/report_database_service.dart';
import 'camera_screen.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'qr_scanner_screen.dart';
import 'report_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardScaffold();
  }
}

class _DashboardActions {
  static final ReportDatabaseService _reportService =
      ReportDatabaseService();

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  static void openAddReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  static void openMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  static void openMyReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyReportsScreen()),
    );
  }

  static void openQrScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  static void openReportDetail(BuildContext context, Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(report: report),
      ),
    );
  }

  static Stream<List<Report>> reportStream() {
    return _reportService.getReports();
  }
}

class _ReportTile extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _ReportTile({
    required this.report,
    required this.onTap,
  });

  String get _locationText {
    if (report.streetName.trim().isNotEmpty) {
      return report.streetName;
    }
    return 'Lat: ${report.latitude.toStringAsFixed(5)}, Lng: ${report.longitude.toStringAsFixed(5)}';
  }

  String get _dateText {
    final date = report.createdAt;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String get _subtitleText {
    if (report.note.trim().isNotEmpty) {
      return '${_dateText} • ${report.note.trim()}';
    }
    return _dateText;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = report.imagePath.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(report.imagePath),
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.image_not_supported,
                  color: Colors.grey.shade600,
                ),
        ),
        title: Text(
          _locationText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_subtitleText),
        onTap: onTap,
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Lihat Peta Laporan'),
              subtitle: const Text('Tampilkan laporan di peta'),
              onTap: () => _DashboardActions.openMap(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Laporan'),
              subtitle: const Text('Buka detail laporan dari QR'),
              onTap: () => _DashboardActions.openQrScanner(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Laporan Saya'),
              subtitle: const Text('Kelola laporan milik saya'),
              onTap: () => _DashboardActions.openMyReports(context),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Laporan Jalan Rusak Terbaru',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari nama jalan...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _queryNotifier.value = value.trim().toLowerCase();
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _queryNotifier,
              builder: (context, query, _) {
                return StreamBuilder<List<Report>>(
                  stream: _DashboardActions.reportStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Gagal memuat laporan'));
                    }

                    final reports = snapshot.data ?? [];
                    final filtered = query.isEmpty
                        ? reports
                        : reports
                            .where((report) => report.streetName
                                .toLowerCase()
                                .contains(query))
                            .toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('Belum ada laporan jalan rusak'),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final report = filtered[index];

                        return _ReportTile(
                          report: report,
                          onTap: () => _DashboardActions.openReportDetail(
                            context,
                            report,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeRoute'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _DashboardActions.logout,
          ),
        ],
      ),
      body: const _DashboardBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _DashboardActions.openAddReport(context),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

