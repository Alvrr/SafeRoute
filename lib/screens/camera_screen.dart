import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_model.dart';
import '../services/location_service.dart';
import '../services/report_database_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final ReportDatabaseService _reportService = ReportDatabaseService();
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  double? _latitude;
  double? _longitude;
  String _streetName = '';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    try {
      final position = await LocationService().getCurrentLocation();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User belum login')),
        );
        return;
      }

      final streetName = await _resolveStreetName(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _image = File(photo.path);
        _latitude = position.latitude;
        _longitude = position.longitude;
        _streetName = streetName;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _saveReport() async {
    if (_image == null || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil foto terlebih dahulu')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum login')),
      );
      return;
    }

    final emailPrefix = (user.email ?? user.uid).split('@').first;

    setState(() => _isSaving = true);

    try {
      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: _image!.path,
        streetName: _streetName,
        note: _noteController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        createdAt: DateTime.now(),
        userId: emailPrefix,
      );

      await _reportService.addReport(report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan tersimpan')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<String> _resolveStreetName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '';

      final place = placemarks.first;
      final parts = <String?>[
        place.street,
        place.subLocality,
        place.locality,
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Foto Kondisi')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_image != null)
            Image.file(
              _image!,
              height: 300,
            )
          else
            const Text('Belum ada foto'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ambil Foto'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveReport,
            icon: const Icon(Icons.save),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Laporan'),
          ),
        ],
      ),
    );
  }
}
