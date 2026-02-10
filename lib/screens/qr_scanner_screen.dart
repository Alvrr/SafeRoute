import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
  as mlkit;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/report_model.dart';
import '../services/report_database_service.dart';
import 'report_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController _controller = MobileScannerController();
  final ReportDatabaseService _reportService = ReportDatabaseService();
    final mlkit.BarcodeScanner _barcodeScanner =
      mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    await _processCode(code);
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;

    try {
      final hasPermission = await _requestGalleryPermission();
      if (!hasPermission) return;

      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isProcessing = true);

      final inputImage = mlkit.InputImage.fromFilePath(image.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);
      final code = barcodes.isNotEmpty ? barcodes.first.rawValue : null;

      if (code == null || code.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR tidak ditemukan')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      await _processCode(code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<bool> _requestGalleryPermission() async {
    PermissionStatus status = await Permission.photos.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) return true;

    if (!mounted) return false;
    await _showPermissionDialog(
      title: 'Izin galeri diperlukan',
      message: 'Aktifkan izin galeri agar bisa memilih gambar QR.',
      canOpenSettings: status.isPermanentlyDenied,
    );
    return false;
  }

  Future<void> _showPermissionDialog({
    required String title,
    required String message,
    required bool canOpenSettings,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (canOpenSettings)
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Buka Pengaturan'),
            ),
        ],
      ),
    );
  }

  Future<void> _processCode(String code) async {
    setState(() => _isProcessing = true);
    _controller.stop();

    final reportId = _extractReportId(code);
    if (reportId != null && reportId.isNotEmpty) {
      final report = await _reportService.getReportById(reportId);
      if (!mounted) return;

      if (report == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan tidak ditemukan')),
        );
        setState(() => _isProcessing = false);
        _controller.start();
        return;
      }

      await _openReportDetail(report);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hasil Scan'),
        content: Text(code),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _controller.start();
      }
    });
  }

  Future<void> _openReportDetail(Report report) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(report: report),
      ),
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _controller.start();
  }

  String? _extractReportId(String code) {
    if (code.startsWith('saferoute://report/')) {
      return code.replaceFirst('saferoute://report/', '').trim();
    }

    final uri = Uri.tryParse(code);
    if (uri != null) {
      final idFromQuery = uri.queryParameters['id'];
      if (idFromQuery != null && idFromQuery.isNotEmpty) {
        return idFromQuery;
      }
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }

    if (RegExp(r'^\d{10,}$').hasMatch(code)) {
      return code;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _scanFromGallery,
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _handleDetect,
      ),
    );
  }
}
