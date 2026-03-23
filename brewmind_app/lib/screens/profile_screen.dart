import 'package:brewmind_app/screens/leaderboard_screen.dart';
import 'package:brewmind_app/screens/order_history_screen.dart';
import 'package:brewmind_app/screens/star_points_screen.dart';
import 'package:brewmind_app/screens/edit_profile_screen.dart';
import 'package:brewmind_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  void _refreshUser() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _displayName = user?.displayName ?? 'User';
      _email = user?.email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = _displayName.isNotEmpty
        ? _displayName[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0E8DC),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFC8965A),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF1A1714),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF0E8DC),
                          ),
                        ),
                        Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9A8C7E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _menuItem(
                Icons.history_outlined,
                'Order History',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                ),
              ),
              _menuItem(
                Icons.leaderboard_outlined,
                'Leaderboard',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                ),
              ),
              _menuItem(
                Icons.star_rounded,
                'My Star Points',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StarPointsScreen()),
                ),
              ),
              _menuItem(Icons.person_outline, 'Edit Profile', () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                if (updated == true) _refreshUser();
              }),

              const Spacer(),

              // Sign out button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await AuthService().logout();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4856A),
                    side: const BorderSide(color: Color(0x33D4856A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF2E2820))),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9A8C7E), size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF0E8DC),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF5A504A), size: 18),
          ],
        ),
      ),
    );
  }
}