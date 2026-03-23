import 'package:brewmind_app/models/drink_model.dart';
import 'package:brewmind_app/screens/drink_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/drink_service.dart';
import 'chatbot_screen.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String? _selectedMood;
  List<DrinkModel> _recommendations = [];
  bool _loadingDrinks = false;
  bool _loadingUser = true;
  List<String> _userAllergies = [];
  String _userName = '';
  String? _errorMessage;

  final _drinkService = DrinkService();

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Happy', 'value': 'happy', 'color': 0xFFF4C430},
    {
      'emoji': '😌',
      'label': 'Relaxed',
      'value': 'relaxed',
      'color': 0xFF7EB8A4,
    },
    {
      'emoji': '😰',
      'label': 'Stressed',
      'value': 'stressed',
      'color': 0xFFA89BC0,
    },
    {'emoji': '😴', 'label': 'Tired', 'value': 'tired', 'color': 0xFFD4856A},
    {
      'emoji': '⚡',
      'label': 'Energetic',
      'value': 'energetic',
      'color': 0xFFC8965A,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _loadingUser = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _userName = 'Guest';
          _loadingUser = false;
        });
        return;
      }

      print('👤 Loading user data for: $uid');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _userName = (data['name'] as String? ?? '').split(' ').first;
          if (_userName.isEmpty) _userName = 'there';
          _userAllergies = List<String>.from(
            (data['allergies'] as List?)?.map(
                  (e) => e.toString().toLowerCase(),
                ) ??
                [],
          );
          _loadingUser = false;
        });
        print('✅ User loaded: $_userName | Allergies: $_userAllergies');
      } else {
        final authUser = FirebaseAuth.instance.currentUser;
        setState(() {
          _userName = authUser?.displayName?.split(' ').first ?? 'there';
          _loadingUser = false;
        });
        print('⚠️ No Firestore user doc — using Auth name: $_userName');
      }
    } catch (e) {
      print('❌ _loadUserData error: $e');
      setState(() {
        _userName = 'there';
        _loadingUser = false;
      });
    }
  }

  Future<void> _selectMood(String mood) async {
    setState(() {
      _selectedMood = mood;
      _loadingDrinks = true;
      _errorMessage = null;
      _recommendations = [];
    });

    try {
      final drinks = await _drinkService.getRecommendations(
        mood,
        _userAllergies,
      );

      setState(() {
        _recommendations = drinks;
        _loadingDrinks = false;
      });

      if (drinks.isEmpty) {
        print('⚠️ No drinks found for mood: $mood');
      }
    } catch (e) {
      print('❌ _selectMood error: $e');
      setState(() {
        _loadingDrinks = false;
        _errorMessage =
            'Could not load drinks. Check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFC8965A),
          backgroundColor: const Color(0xFF1A1714),
          onRefresh: _loadUserData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _loadingUser
                              ? Container(
                                  width: 120,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E2820),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                )
                              : Text(
                                  'Hello, $_userName 👋',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9A8C7E),
                                  ),
                                ),
                          const SizedBox(height: 4),
                          const Text(
                            'How are you feeling?',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF0E8DC),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatbotScreen(),
                          ),
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1714),
                            border: Border.all(color: const Color(0xFF2E2820)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('🤖', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_userAllergies.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x15D4856A),
                        border: Border.all(color: const Color(0x33D4856A)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              'Filtering out: ${_userAllergies.join(', ')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD4856A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT YOUR MOOD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A504A),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                        children: _moods.map((mood) {
                          final isSelected = _selectedMood == mood['value'];
                          return GestureDetector(
                            onTap: () => _selectMood(mood['value'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(
                                        mood['color'] as int,
                                      ).withOpacity(0.15)
                                    : const Color(0xFF1A1714),
                                border: Border.all(
                                  color: isSelected
                                      ? Color(
                                          mood['color'] as int,
                                        ).withOpacity(0.6)
                                      : const Color(0xFF2E2820),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    mood['emoji'] as String,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    mood['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Color(mood['color'] as int)
                                          : const Color(0xFF9A8C7E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Recommendations
              if (_selectedMood != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'RECOMMENDED FOR YOU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5A504A),
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            if (!_loadingDrinks)
                              Text(
                                '${_recommendations.length} drink${_recommendations.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5A504A),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Loading state
                        if (_loadingDrinks)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: Color(0xFFC8965A),
                              ),
                            ),
                          )
                        // Error state
                        else if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1714),
                              border: Border.all(
                                color: const Color(0x33D4856A),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '❌ ',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFD4856A),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            _selectMood(_selectedMood!),
                                        child: const Text(
                                          'Tap to retry →',
                                          style: TextStyle(
                                            color: Color(0xFFC8965A),
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Color(0xFFC8965A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        // No drinks found
                        else if (_recommendations.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1714),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2E2820),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('☕', style: TextStyle(fontSize: 32)),
                                const SizedBox(height: 8),
                                const Text(
                                  'No drinks found',
                                  style: TextStyle(
                                    color: Color(0xFFF0E8DC),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userAllergies.isNotEmpty
                                      ? 'No drinks match your mood and allergy settings.\nTry a different mood!'
                                      : 'No drinks added for this mood yet.\nAdd drinks in the admin dashboard!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF9A8C7E),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        // Drink cards
                        else
                          ..._recommendations.map(
                            (drink) => _DrinkRecommendCard(
                              drink: drink,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DrinkDetailScreen(drink: drink),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// Drink recommendation card
class _DrinkRecommendCard extends StatelessWidget {
  final DrinkModel drink;
  final VoidCallback onTap;
  const _DrinkRecommendCard({required this.drink, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1714),
          border: Border.all(color: const Color(0xFF2E2820)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Emoji
            Text(
              drink.emoji.isNotEmpty ? drink.emoji : '☕',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.name,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF0E8DC),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    drink.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A8C7E),
                    ),
                  ),
                  if (drink.allergens.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      '⚠ Contains: ${drink.allergens.join(', ')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD4856A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${drink.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC8965A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to view',
                  style: TextStyle(fontSize: 10, color: Color(0xFF5A504A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}