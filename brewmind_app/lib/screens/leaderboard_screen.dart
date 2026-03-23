import 'package:brewmind_app/services/loyalty_service.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LoyaltyService().getLeaderboard();
    setState(() {
      _leaderboard = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        title: const Text(
          '⭐ Leaderboard',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0F0D0B),
        foregroundColor: const Color(0xFFF0E8DC),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8965A)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _leaderboard.length,
              itemBuilder: (ctx, i) {
                final user = _leaderboard[i];
                final rank = user['rank'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? const Color(0x15C8965A)
                        : const Color(0xFF1A1714),
                    border: Border.all(
                      color: rank == 1
                          ? const Color(0x33C8965A)
                          : const Color(0xFF2E2820),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                          style: TextStyle(
                            fontSize: rank <= 3 ? 20 : 13,
                            color: const Color(0xFF9A8C7E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFC8965A),
                        child: Text(
                          user['name'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF1A1714),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user['name'],
                          style: const TextStyle(
                            color: Color(0xFFF0E8DC),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${user['points']} ⭐',
                        style: const TextStyle(
                          color: Color(0xFFC8965A),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}