import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StarPointsScreen extends StatefulWidget {
  const StarPointsScreen({super.key});
  @override
  State<StarPointsScreen> createState() => _StarPointsScreenState();
}

class _StarPointsScreenState extends State<StarPointsScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  int _starPoints = 0;
  int _totalOrders = 0;
  int _rank = 0;
  bool _loading = true;

  // Transaction history list
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tier helpers
  String get _tierName {
    if (_starPoints >= 600) return 'Platinum';
    if (_starPoints >= 300) return 'Gold';
    if (_starPoints >= 100) return 'Silver';
    return 'Bronze';
  }

  String get _tierEmoji {
    if (_starPoints >= 600) return '💎';
    if (_starPoints >= 300) return '🥇';
    if (_starPoints >= 100) return '🥈';
    return '🥉';
  }

  Color get _tierColor {
    if (_starPoints >= 600) return const Color(0xFF7EB8A4);
    if (_starPoints >= 300) return const Color(0xFFC8965A);
    if (_starPoints >= 100) return const Color(0xFF9A8C7E);
    return const Color(0xFFD4856A);
  }

  int get _nextTierPoints {
    if (_starPoints >= 600) return 600;
    if (_starPoints >= 300) return 600;
    if (_starPoints >= 100) return 300;
    return 100;
  }

  int get _currentTierMin {
    if (_starPoints >= 600) return 600;
    if (_starPoints >= 300) return 300;
    if (_starPoints >= 100) return 100;
    return 0;
  }

  double get _tierProgress {
    if (_starPoints >= 600) return 1.0;
    final range = _nextTierPoints - _currentTierMin;
    final progress = _starPoints - _currentTierMin;
    return (progress / range).clamp(0.0, 1.0);
  }

  // Load all data
  Future<void> _loadData() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // 1. Load star points from user document

      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          _starPoints = userDoc.data()?['starPoints'] ?? 0;
        });
      }

      // 2. Count orders

      final ordersSnap = await _db
          .collection('orders')
          .where('userID', isEqualTo: uid)
          .get();
      setState(() => _totalOrders = ordersSnap.size);

      // 3. Get leaderboard rank

      final lbSnap = await _db.collection('leaderboard').get();
      final sorted =
          lbSnap.docs
              .map((d) => {'id': d.id, 'points': d.data()['points'] ?? 0})
              .toList()
            ..sort(
              (a, b) => (b['points'] as int).compareTo(a['points'] as int),
            );
      final idx = sorted.indexWhere((e) => e['id'] == uid);
      setState(() => _rank = idx == -1 ? 0 : idx + 1);

      // 4. Build transaction history from orders + reservations

      final List<Map<String, dynamic>> txns = [];

      for (final doc in ordersSnap.docs) {
        final d = doc.data();
        txns.add({
          'icon': '☕',
          'label': 'Order placed',
          'pts': '+10',
          'color': const Color(0xFFC8965A),
          'date': d['date'],
        });
      }

      final resSnap = await _db
          .collection('reservations')
          .where('userID', isEqualTo: uid)
          .get();

      for (final doc in resSnap.docs) {
        final d = doc.data();
        if (d['status'] != 'cancelled') {
          txns.add({
            'icon': '🪑',
            'label': 'Table reserved',
            'pts': '+5',
            'color': const Color(0xFF7EB8A4),
            'date': d['createdAt'],
          });
        }
      }

      // Sort newest first

      txns.sort((a, b) {
        final da = a['date'];
        final db2 = b['date'];
        if (da == null) return 1;
        if (db2 == null) return -1;
        final ta = da is Timestamp ? da.toDate() : DateTime.now();
        final tb = db2 is Timestamp ? db2.toDate() : DateTime.now();
        return tb.compareTo(ta);
      });

      setState(() {
        _transactions = txns;
        _loading = false;
      });
    } catch (e) {
      print('❌ StarPoints load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        title: const Text(
          'My Star Points',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0F0D0B),
        foregroundColor: const Color(0xFFF0E8DC),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF9A8C7E),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8965A)),
            )
          : RefreshIndicator(
              color: const Color(0xFFC8965A),
              backgroundColor: const Color(0xFF1A1714),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPointsCard(),
                    const SizedBox(height: 20),

                    _buildStatsRow(),
                    const SizedBox(height: 20),

                    _buildTierRewards(),
                    const SizedBox(height: 20),

                    _buildHowToEarn(),
                    const SizedBox(height: 24),

                    _buildPointsHistory(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1F0E), Color(0xFF1A1714)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x55C8965A)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('⭐', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Text(
                    'Star Points',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC8965A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _tierColor.withOpacity(0.15),
                  border: Border.all(color: _tierColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_tierEmoji $_tierName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$_starPoints',
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC8965A),
              height: 1,
            ),
          ),
          const Text(
            'points',
            style: TextStyle(fontSize: 15, color: Color(0xFF9A8C7E)),
          ),
          const SizedBox(height: 20),

          // Progress bar to next tier
          if (_starPoints < 600) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to next tier',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A8C7E),
                  ),
                ),
                Text(
                  '${_nextTierPoints - _starPoints} pts to go',
                  style: TextStyle(
                    fontSize: 12,
                    color: _tierColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _tierProgress,
                minHeight: 10,
                backgroundColor: const Color(0xFF2E2820),
                valueColor: AlwaysStoppedAnimation(_tierColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tierName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5A504A),
                  ),
                ),
                Text(
                  _starPoints >= 300
                      ? 'Platinum 💎'
                      : _starPoints >= 100
                      ? 'Gold 🥇'
                      : 'Silver 🥈',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5A504A),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x157EB8A4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x337EB8A4)),
              ),
              child: const Row(
                children: [
                  Text('💎', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10),
                  Text(
                    'You reached Platinum — highest tier!',
                    style: TextStyle(
                      color: Color(0xFF7EB8A4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(
          emoji: '◎',
          label: 'Total Orders',
          value: '$_totalOrders',
          color: const Color(0xFFC8965A),
        ),
        const SizedBox(width: 12),
        _StatCard(
          emoji: '◆',
          label: 'Leaderboard Rank',
          value: _rank > 0 ? '#$_rank' : '—',
          color: const Color(0xFFA89BC0),
        ),
        const SizedBox(width: 12),
        _StatCard(
          emoji: '⭐',
          label: 'Points Earned',
          value: '$_starPoints',
          color: const Color(0xFF7EB8A4),
        ),
      ],
    );
  }

  Widget _buildTierRewards() {
    final tiers = [
      {
        'emoji': '🥉',
        'name': 'Bronze',
        'range': '0 – 99 pts',
        'reward': 'Member access',
        'active': _starPoints < 100,
      },
      {
        'emoji': '🥈',
        'name': 'Silver',
        'range': '100 – 299 pts',
        'reward': '1 free drink',
        'active': _starPoints >= 100 && _starPoints < 300,
      },
      {
        'emoji': '🥇',
        'name': 'Gold',
        'range': '300 – 599 pts',
        'reward': 'Priority orders',
        'active': _starPoints >= 300 && _starPoints < 600,
      },
      {
        'emoji': '💎',
        'name': 'Platinum',
        'range': '600+ pts',
        'reward': 'VIP perks',
        'active': _starPoints >= 600,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIER REWARDS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5A504A),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ...tiers.map((tier) {
          final isActive = tier['active'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0x22C8965A)
                  : const Color(0xFF1A1714),
              border: Border.all(
                color: isActive
                    ? const Color(0x55C8965A)
                    : const Color(0xFF2E2820),
                width: isActive ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  tier['emoji'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier['name'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? const Color(0xFFC8965A)
                                  : const Color(0xFFF0E8DC),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC8965A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1714),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tier['range'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9A8C7E),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tier['reward'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? const Color(0xFFC8965A)
                        : const Color(0xFF5A504A),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHowToEarn() {
    final ways = [
      {'icon': '☕', 'action': 'Place an order', 'pts': '+10 pts'},
      {'icon': '🪑', 'action': 'Make a reservation', 'pts': '+5 pts'},
      {'icon': '🎂', 'action': 'Birthday bonus', 'pts': '+50 pts'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOW TO EARN POINTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5A504A),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1714),
            border: Border.all(color: const Color(0xFF2E2820)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: ways
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF231F1B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              w['icon']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            w['action']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFF0E8DC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x22C8965A),
                            border: Border.all(color: const Color(0x44C8965A)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            w['pts']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC8965A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'POINTS HISTORY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A504A),
                letterSpacing: 2,
              ),
            ),
            Text(
              '${_transactions.length} transactions',
              style: const TextStyle(fontSize: 11, color: Color(0xFF5A504A)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1714),
              border: Border.all(color: const Color(0xFF2E2820)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Column(
                children: [
                  Text('⭐', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 8),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Color(0xFF9A8C7E), fontSize: 14),
                  ),
                  Text(
                    'Place an order to earn your first points!',
                    style: TextStyle(color: Color(0xFF5A504A), fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ..._transactions.map((t) {
            // Format date

            final ts = t['date'];
            String dateStr = '';
            if (ts is Timestamp) {
              final d = ts.toDate().toLocal();
              dateStr =
                  '${d.day}/${d.month}/${d.year}  '
                  '${d.hour.toString().padLeft(2, '0')}:'
                  '${d.minute.toString().padLeft(2, '0')}';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1714),
                border: Border.all(color: const Color(0xFF2E2820)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (t['color'] as Color).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        t['icon'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['label'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF0E8DC),
                          ),
                        ),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5A504A),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: (t['color'] as Color).withOpacity(0.15),
                      border: Border.all(
                        color: (t['color'] as Color).withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t['pts'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1714),
          border: Border.all(color: const Color(0xFF2E2820)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: TextStyle(fontSize: 16, color: color)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9A8C7E)),
            ),
          ],
        ),
      ),
    );
  }
}