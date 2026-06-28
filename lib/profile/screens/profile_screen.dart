import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../screens/loginscreen.dart'; // ✅ fixed import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  List<dynamic> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lb = await _api.getLeaderboard();
    if (mounted) setState(() { _leaderboard = lb; _loading = false; });
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
        title: const Text('Profile',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Colors.white54, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text('Citizen',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Active Reporter',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                ),

                const SizedBox(height: 28),
                const _SectionLabel('LEADERBOARD'),
                const SizedBox(height: 12),

                if (_leaderboard.isEmpty)
                  const Center(
                    child: Text('No data yet',
                        style: TextStyle(color: Colors.white38)),
                  )
                else
                  ..._leaderboard.take(10).map((u) {
                    final rank   = u['rank'] ?? 0;
                    final name   = u['name'] ?? 'Citizen';
                    final points = u['reward_points'] ?? 0;
                    final badge  = u['badge'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232B45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(children: [
                        Text(
                          '#$rank',
                          style: TextStyle(
                              color: rank <= 3
                                  ? const Color(0xFFFFD700)
                                  : Colors.white38,
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              if (badge.isNotEmpty)
                                Text(badge,
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          '$points pts',
                          style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    );
                  }),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w700));
}