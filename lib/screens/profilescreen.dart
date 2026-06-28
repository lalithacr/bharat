import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final data = await ApiService().getLeaderboard();
      if (mounted) setState(() { _leaderboard = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(children: [
          // Profile header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2340), Color(0xFF243055)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(children: [
              Row(children: [
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    await ApiService().clearToken();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
                  tooltip: 'Logout',
                ),
              ]),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFFF6B35).withOpacity(0.2),
                child: Text(widget.user.initials,
                    style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              Text(widget.user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.verified, color: Color(0xFFFF6B35), size: 14),
                const SizedBox(width: 5),
                Text(widget.user.badge,
                    style: const TextStyle(
                        color: Color(0xFFFF8C60), fontSize: 13)),
              ]),
              if (widget.user.phone != null) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.phone, size: 12, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 5),
                  Text(widget.user.phone!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ]),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(Icons.stars_rounded, '${widget.user.rewardPoints}',
                      'Points', const Color(0xFFE8A020)),
                  Container(width: 1, height: 36, color: Colors.white12),
                  _StatItem(Icons.shield_outlined,
                      '${(widget.user.trustScore * 100).toInt()}%', 'Trust Score',
                      const Color(0xFF4CAF50)),
                  Container(width: 1, height: 36, color: Colors.white12),
                  _StatItem(Icons.language,
                      widget.user.preferredLang.toUpperCase(), 'Language',
                      const Color(0xFF5BA4F5)),
                ],
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Badges
              _Section(
                icon: Icons.military_tech,
                title: 'My Badges',
                child: Column(children: [
                  _BadgeRow(Icons.eco, 'New Reporter',
                      'Submit your first report', widget.user.rewardPoints >= 0,
                      const Color(0xFF138808)),
                  _BadgeRow(Icons.star, 'Problem Solver',
                      'Earn 50+ points', widget.user.rewardPoints >= 50,
                      const Color(0xFFE8A020)),
                  _BadgeRow(Icons.shield, 'Area Guardian',
                      'Earn 200+ points', widget.user.rewardPoints >= 200,
                      const Color(0xFF0066CC)),
                  _BadgeRow(Icons.emoji_events, 'Civic Hero',
                      'Earn 500+ points', widget.user.rewardPoints >= 500,
                      const Color(0xFFFF6B35)),
                ]),
              ),
              const SizedBox(height: 14),

              // Leaderboard
              _Section(
                icon: Icons.leaderboard,
                title: 'City Leaderboard',
                child: _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: Color(0xFFFF6B35)),
                        ))
                    : _leaderboard.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No data yet',
                                style: TextStyle(color: Color(0xFF8C8A82))),
                          )
                        : Column(
                            children: _leaderboard.take(5).map((entry) {
                              final e = entry as Map<String, dynamic>;
                              final rank = e['rank'] as int;
                              return _LeaderboardRow(
                                rank: rank,
                                name: e['name'] as String,
                                badge: e['badge'] as String,
                                points: e['reward_points'] as int,
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 14),

              // Settings
              _Section(
                icon: Icons.settings_outlined,
                title: 'Account',
                child: Column(children: [
                  _SettingsTile(Icons.notifications_outlined, 'Notifications', () {}),
                  _SettingsTile(Icons.language, 'Language Preference', () {}),
                  _SettingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
                  _SettingsTile(Icons.help_outline, 'Help & Support', () {}),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red, size: 18),
                    ),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.red),
                    onTap: () async {
                      await ApiService().clearToken();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatItem(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 10)),
      ]);
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEdE8)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Icon(icon, color: const Color(0xFFFF6B35), size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A2340))),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEdE8)),
          child,
        ]),
      );
}

class _BadgeRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool unlocked;
  final Color color;
  const _BadgeRow(this.icon, this.title, this.subtitle, this.unlocked, this.color);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: unlocked ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: unlocked ? color : Colors.grey.shade400, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: unlocked ? const Color(0xFF1A2340) : Colors.grey)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8C8A82))),
        trailing: unlocked
            ? Icon(Icons.check_circle, color: color, size: 18)
            : Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 16),
      );
}

class _LeaderboardRow extends StatelessWidget {
  final int rank, points;
  final String name, badge;
  const _LeaderboardRow(
      {required this.rank,
      required this.name,
      required this.badge,
      required this.points});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final medalColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isTop3
              ? medalColors[rank - 1].withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isTop3
            ? Icon(Icons.emoji_events,
                color: medalColors[rank - 1], size: 20)
            : Center(
                child: Text('#$rank',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF8C8A82)))),
      ),
      title: Text(name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(badge,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8C8A82))),
      trailing: Text('$points pts',
          style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SettingsTile(this.icon, this.title, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1A2340), size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF1A2340))),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: Color(0xFF8C8A82)),
        onTap: onTap,
      );
}