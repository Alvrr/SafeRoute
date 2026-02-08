import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gal/gal.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/report_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {

  String get _dateText {
    final date = widget.report.createdAt;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final position = LatLng(report.latitude, report.longitude);
    final qrData = 'https://saferoute.app/report?id=${report.id}';

    Future<void> openInGoogleMaps() async {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${report.latitude},${report.longitude}&travelmode=driving',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
        );
      }
    }

    Future<void> generateAndSaveQr() async {
      final granted = await Gal.requestAccess();
      if (!granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin galeri ditolak')),
        );
        return;
      }

      try {
        final painter = QrPainter(
          data: qrData,
          version: QrVersions.auto,
          gapless: false,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        );

        final qrImage = await painter.toImage(900);
        final paddedImage = await _addPadding(qrImage, 80);
        final byteData =
            await paddedImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw Exception('Gagal membuat QR');
        }

        final pngBytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/saferoute_qr_${report.id}.png');
        await file.writeAsBytes(Uint8List.fromList(pngBytes));

        await Gal.putImage(file.path);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR tersimpan di galeri')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            report.streetName.isNotEmpty
                ? report.streetName
                : 'Lokasi tidak diketahui',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text('Tanggal: $_dateText'),
          const SizedBox(height: 4),
          Text('Pelapor: ${report.userId}'),
          const SizedBox(height: 4),
          Text('Koordinat: ${report.latitude}, ${report.longitude}'),
          const SizedBox(height: 12),
          if (report.note.trim().isNotEmpty)
            Text('Catatan: ${report.note.trim()}'),
          const SizedBox(height: 16),
          if (report.imagePath.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(report.imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            const SizedBox(
              height: 120,
              child: Center(child: Text('Foto tidak tersedia')),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: generateAndSaveQr,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Laporan'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.saferoute',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: position,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: openInGoogleMaps,
              icon: const Icon(Icons.directions),
              label: const Text('Arahkan ke Lokasi'),
            ),
          ),
        ],
      ),
    );
  }

  Future<ui.Image> _addPadding(ui.Image image, int padding) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(
      image.width.toDouble() + padding * 2,
      image.height.toDouble() + padding * 2,
    );

    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, paint);
    canvas.drawImage(image, Offset(padding.toDouble(), padding.toDouble()), Paint());

    final picture = recorder.endRecording();
    return picture.toImage(size.width.toInt(), size.height.toInt());
  }
}
