import 'package:flutter/material.dart';
import '../services/location_service.dart';

class GpsTestScreen extends StatefulWidget {
  const GpsTestScreen({super.key});

  @override
  State<GpsTestScreen> createState() => _GpsTestScreenState();
}

class _GpsTestScreenState extends State<GpsTestScreen> {
  String _location = 'Belum diambil';

  void _getLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      setState(() {
        _location =
            'Lat: ${position.latitude}, Lng: ${position.longitude}';
      });
    } catch (e) {
      setState(() {
        _location = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tes GPS')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_location),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getLocation,
              child: const Text('Ambil Lokasi'),
            ),
          ],
        ),
      ),
    );
  }
}
