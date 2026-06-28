import 'package:flutter/material.dart';
import '../core/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  List<dynamic> _reports = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats   = await _api.getDashboardStats();
    final reports = await _api.getMyReports();
    if (mounted) {
      setState(() {
        _stats   = stats;
        _reports = reports;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _api.clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'resolved':    return Colors.greenAccent;
      case 'in_progress': return Colors.blueAccent;
      case 'assigned':    return Colors.purpleAccent;
      case 'rejected':    return Colors.redAccent;
      default:            return Colors.white38;
    }
  }

  IconData _issueIcon(String t) {
    switch (t) {
      case 'pothole':             return Icons.warning_amber_rounded;
      case 'garbage':             return Icons.delete_outline_rounded;
      case 'water_leakage':       return Icons.water_drop_outlined;
      case 'broken_street_light': return Icons.lightbulb_outline_rounded;
      case 'flooding':            return Icons.waves_rounded;
      case 'damaged_road':        return Icons.terrain_outlined;
      default:                    return Icons.report_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2035),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232B45),
        title: const Text('Bharat Problem Solver',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : RefreshIndicator(
              color: const Color(0xFFFF6B35),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Stats row ───────────────────────────────────────────
                  Row(children: [
                    _StatBox(
                        label: 'Total',
                        value: '${_stats['total_reports'] ?? _reports.length}',
                        color: const Color(0xFFFF6B35)),
                    const SizedBox(width: 10),
                    _StatBox(
                        label: 'Resolved',
                        value: '${_stats['resolved'] ?? 0}',
                        color: Colors.greenAccent),
                    const SizedBox(width: 10),
                    _StatBox(
                        label: 'Pending',
                        value: '${_stats['pending'] ?? 0}',
                        color: Colors.blueAccent),
                  ]),

                  const SizedBox(height: 24),
                  const Text('MY REPORTS',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  if (_reports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232B45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(children: [
                          Icon(Icons.inbox_outlined,
                              color: Colors.white24, size: 40),
                          SizedBox(height: 12),
                          Text('No reports yet.',
                              style: TextStyle(color: Colors.white38)),
                        ]),
                      ),
                    )
                  else
                    ..._reports.map((r) {
                      final type   = (r['issue_type'] ?? 'other') as String;
                      final status = (r['status'] ?? 'pending') as String;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF232B45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_issueIcon(type),
                                color: const Color(0xFFFF6B35), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                if (r['address'] != null)
                                  Text(r['address'],
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11),
                                      overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _statusColor(status).withOpacity(0.4)),
                            ),
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
        label: const Text('Report Issue',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                  letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}