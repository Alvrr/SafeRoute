import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/report_database_service.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  String _emailPrefix(User? user) {
    if (user?.email == null || user!.email!.isEmpty) {
      return user?.uid ?? '';
    }
    return user.email!.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = _emailPrefix(currentUser);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Saya'),
      ),
      body: StreamBuilder<List<Report>>(
        stream: ReportDatabaseService().getReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat laporan'));
          }

          final allReports = snapshot.data ?? [];
          final reports = allReports
              .where((report) => report.userId == currentUserId)
              .toList();

          if (reports.isEmpty) {
            return const Center(child: Text('Belum ada laporan saya'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final report = reports[index];
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
                    report.streetName.isNotEmpty
                        ? report.streetName
                        : 'Lat: ${report.latitude.toStringAsFixed(5)}, Lng: ${report.longitude.toStringAsFixed(5)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle:
                      Text(report.note.isNotEmpty ? report.note : 'Tanpa catatan'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ReportDatabaseService().deleteReport(report.id);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailScreen(report: report),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
