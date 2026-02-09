import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/report_model.dart';
import '../services/report_database_service.dart';
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

  static const LatLng _initialCenter = LatLng(-2.548926, 118.0148634);
  static const double _initialZoom = 5.0;

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

  @override
  void dispose() {
    _searchController.dispose();
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
