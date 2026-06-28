import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiService();
  List<dynamic> _nearby = [];
  bool _loading = true;

  // Default to Coimbatore
  final double _lat = 11.0168;
  final double _lng = 76.9558;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await _api.getNearbyReports(
        lat: _lat, lng: _lng, radiusKm: 5.0);
    if (mounted) {
      setState(() { _nearby = reports; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2035),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232B45),
        title: const Text('Nearby Issues',
            style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFF6B35)))
          : Column(children: [
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF232B45),
                child: Row(children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFFFF6B35), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Showing ${_nearby.length} reports within 5km',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ]),
              ),
              Expanded(
                child: _nearby.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined,
                                color: Colors.white24, size: 48),
                            SizedBox(height: 12),
                            Text('No reports nearby',
                                style: TextStyle(
                                    color: Colors.white38)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _nearby.length,
                        itemBuilder: (_, i) {
                          final r = _nearby[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF232B45),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.white12),
                            ),
                            child: Row(children: [
                              const Icon(Icons.report_outlined,
                                  color: Color(0xFFFF6B35), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (r['issue_type'] ?? 'issue')
                                          .toString()
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                    if (r['address'] != null)
                                      Text(r['address'].toString(),
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                          overflow:
                                              TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (r['status'] ?? 'pending')
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}
