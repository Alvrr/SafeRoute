import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/report_model.dart';
import '../services/report_database_service.dart';
import '../services/location_service.dart';
import 'report_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final MapController _mapController = MapController();
  String _lastFitKey = '';
  StreamSubscription<Position>? _positionSub;
  LatLng? _userLocation;
  bool _hasCenteredOnUser = false;

  static const LatLng _initialCenter = LatLng(-2.548926, 118.0148634);
  static const double _initialZoom = 5.0;
  static const double _userViewRadiusKm = 1.0;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  List<Marker> _buildMarkers(BuildContext context, List<Report> reports) {
    return reports.map((report) {
      final position = LatLng(report.latitude, report.longitude);

      return Marker(
        width: 40,
        height: 40,
        point: position,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(report: report),
              ),
            );
          },
          child: const Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 36,
          ),
        ),
      );
    }).toList();
  }

  Marker? _buildUserMarker() {
    final location = _userLocation;
    if (location == null) return null;

    return Marker(
      width: 44,
      height: 44,
      point: location,
      child: const Icon(
        Icons.my_location,
        color: Colors.blueAccent,
        size: 36,
      ),
    );
  }

  Future<void> _initUserLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      _updateUserLocation(position);
      _listenPositionStream();
    } catch (e) {
      if (!mounted) return;
      await _handleLocationError(e.toString());
    }
  }

  void _listenPositionStream() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      _updateUserLocation(position, recenter: false);
    });
  }

  void _updateUserLocation(Position position, {bool recenter = true}) {
    final newLocation = LatLng(position.latitude, position.longitude);
    setState(() => _userLocation = newLocation);

    if (recenter && !_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitToUserLocation(newLocation);
      });
    }
  }

  void _fitToUserLocation(LatLng center) {
    final latDelta = _userViewRadiusKm / 111.32;
    final lonDelta = _userViewRadiusKm /
      (111.32 *
          math.cos(
            center.latitude.abs() * (math.pi / 180),
          ))
        .clamp(0.0001, double.infinity);

    final bounds = LatLngBounds(
      LatLng(center.latitude - latDelta, center.longitude - lonDelta),
      LatLng(center.latitude + latDelta, center.longitude + lonDelta),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  Future<void> _handleLocationError(String message) async {
    if (!mounted) return;
    final lower = message.toLowerCase();
    if (lower.contains('permanen')) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Izin lokasi diperlukan'),
          content: const Text(
            'Aktifkan izin lokasi di Pengaturan agar peta bisa menampilkan posisi Anda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
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
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Laporan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama jalan...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _query = value.trim().toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Report>>(
              stream: ReportDatabaseService().getReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Gagal memuat peta'));
                }

                final reports = snapshot.data ?? [];
                final filtered = _query.isEmpty
                    ? reports
                    : reports
                          .where(
                            (report) => report.streetName
                                .toLowerCase()
                                .contains(_query),
                          )
                          .toList();
                final markers = _buildMarkers(context, filtered);
                final userMarker = _buildUserMarker();
                if (userMarker != null) {
                  markers.add(userMarker);
                }

                if (_query.isNotEmpty && filtered.isNotEmpty) {
                  final fitKey = '${_query}_${filtered.length}';
                  if (fitKey != _lastFitKey) {
                    _lastFitKey = fitKey;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final bounds = LatLngBounds.fromPoints(
                        filtered
                            .map(
                              (report) =>
                                  LatLng(report.latitude, report.longitude),
                            )
                            .toList(),
                      );
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.all(64),
                          maxZoom: 15,
                        ),
                      );
                    });
                  }
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: _initialZoom,
                    minZoom: 4.5,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: LatLngBounds(
                        const LatLng(-11.0, 95.0),
                        const LatLng(6.0, 141.0),
                      ),
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.saferoute',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
