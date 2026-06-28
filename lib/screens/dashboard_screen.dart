import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../data/models/report_model.dart';
import '../screens/loginscreen.dart';
import '../map/map_screen.dart';
import '../report/screens/report_screen.dart';
import '../profile/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  // Key lets us call reload() on the home tab from outside
  final _homeKey = GlobalKey<_HomeTabState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeTab(key: _homeKey),
      const MapScreen(),
      const ReportScreen(),
      const ProfileScreen(),
    ];
  }

  void _onNavTap(int i) {
    // ✅ When switching BACK to Home (0), reload so new reports appear
    if (i == 0 && _navIndex != 0) {
      _homeKey.currentState?.reload();
    }
    setState(() => _navIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _navIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF232B45),
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        currentIndex: _navIndex,
        onTap: _onNavTap,
        selectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _api = ApiService();
  List<ReportModel> _reports = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ Public so DashboardScreen can call it when switching back to Home
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rawReports = await _api.getMyReports();
      final stats = await _api.getSummary();
      if (mounted) {
        setState(() {
          _reports = rawReports
              .map((r) => ReportModel.fromJson(r as Map<String, dynamic>))
              .toList();
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _api.clearToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2035),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232B45),
        elevation: 0,
        title: const Text(
          'Bharat Problem Solver',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Colors.white54, size: 20),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : RefreshIndicator(
              color: const Color(0xFFFF6B35),
              backgroundColor: const Color(0xFF232B45),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    _StatBox(
                      value: '${_stats['total_reports'] ?? _reports.length}',
                      label: 'Total',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.assignment_outlined,
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      value: '${_stats['resolved'] ?? 0}',
                      label: 'Resolved',
                      color: const Color(0xFF22C55E),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      value: '${_stats['pending'] ?? 0}',
                      label: 'Pending',
                      color: const Color(0xFFFF6B35),
                      icon: Icons.hourglass_empty_rounded,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [
                    const Icon(Icons.history_rounded,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'MY REPORTS',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${_reports.length} total',
                      style:
                          const TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (_reports.isEmpty)
                    _EmptyState()
                  else
                    ..._reports.map((r) => _ReportCard(report: r)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final shell =
              context.findAncestorStateOfType<_DashboardScreenState>();
          shell?._onNavTap(2);
        },
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add_a_photo_outlined,
            color: Colors.white, size: 20),
        label: const Text(
          'Report Issue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.65),
                  fontSize: 10,
                  letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

// ── Report card ───────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  Color _statusColor(String s) {
    switch (s) {
      case 'resolved':    return const Color(0xFF22C55E);
      case 'in_progress': return const Color(0xFF3B82F6);
      case 'assigned':    return const Color(0xFF8B5CF6);
      case 'verified':    return const Color(0xFF06B6D4);
      case 'rejected':    return const Color(0xFFEF4444);
      default:            return Colors.white38;
    }
  }

  IconData _issueIcon(String t) {
    switch (t) {
      case 'pothole':      return Icons.warning_amber_rounded;
      case 'garbage':      return Icons.delete_outline_rounded;
      case 'water_leak':   return Icons.water_drop_outlined;
      case 'broken_light': return Icons.lightbulb_outline_rounded;
      case 'flooding':     return Icons.waves_rounded;
      case 'road_damage':  return Icons.terrain_outlined;
      case 'drainage':     return Icons.plumbing_outlined;
      default:             return Icons.report_outlined;
    }
  }

  Color _issueColor(String t) {
    switch (t) {
      case 'pothole':      return const Color(0xFFFFD700);
      case 'garbage':      return const Color(0xFF22C55E);
      case 'water_leak':   return const Color(0xFF06B6D4);
      case 'broken_light': return const Color(0xFF8B5CF6);
      case 'flooding':     return const Color(0xFF3B82F6);
      case 'road_damage':  return const Color(0xFFFF6B35);
      case 'drainage':     return const Color(0xFF00BFFF);
      default:             return const Color(0xFFFF2D78);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iColor = _issueColor(report.issueType);
    final sColor = _statusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF232B45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: iColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_issueIcon(report.issueType), color: iColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report.ticketNumber.isNotEmpty)
                Text(report.ticketNumber,
                    style: TextStyle(
                        color: iColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              Text(
                report.issueType.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.white30, size: 11),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(report.displayAddress,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: sColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sColor.withOpacity(0.4)),
          ),
          child: Text(
            report.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
                color: sColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF232B45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Center(
        child: Column(children: [
          Icon(Icons.inbox_outlined, color: Colors.white24, size: 48),
          SizedBox(height: 12),
          Text('No reports yet',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text('Tap the button below to report a civic issue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white30, fontSize: 12)),
        ]),
      ),
    );
  }
}