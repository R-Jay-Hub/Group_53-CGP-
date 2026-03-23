import 'package:brewmind_app/models/drink_model.dart';
import 'package:brewmind_app/screens/drink_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/drink_service.dart';
import '../services/cart_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _drinkService = DrinkService();
  List<DrinkModel> _allDrinks = [];
  List<DrinkModel> _filtered = [];
  String _search = '';
  String _moodFilter = 'all';
  bool _loading = true;

  final _moods = ['all', 'happy', 'relaxed', 'stressed', 'tired', 'energetic'];
  final _moodLabels = {
    'all': 'All',
    'happy': '😊',
    'relaxed': '😌',
    'stressed': '😰',
    'tired': '😴',
    'energetic': '⚡',
  };

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    final drinks = await _drinkService.getAllDrinks();
    setState(() {
      _allDrinks = drinks;
      _filtered = drinks;
      _loading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allDrinks.where((d) {
        final matchesMood = _moodFilter == 'all' || d.moodTag == _moodFilter;
        final matchesSearch =
            _search.isEmpty ||
            d.name.toLowerCase().contains(_search.toLowerCase());
        return matchesMood && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Menu',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF0E8DC),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search bar
                  TextField(
                    onChanged: (v) {
                      _search = v;
                      _applyFilter();
                    },
                    style: const TextStyle(
                      color: Color(0xFFF0E8DC),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search drinks...',
                      hintStyle: const TextStyle(color: Color(0xFF5A504A)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF5A504A),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1714),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2E2820)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2E2820)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC8965A)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _moods.map((mood) {
                        final isActive = _moodFilter == mood;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _moodFilter = mood);
                            _applyFilter();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0x22C8965A)
                                  : const Color(0xFF1A1714),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0x55C8965A)
                                    : const Color(0xFF2E2820),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _moodLabels[mood]!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isActive
                                    ? const Color(0xFFC8965A)
                                    : const Color(0xFF9A8C7E),
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC8965A),
                      ),
                    )
                  : _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No drinks found',
                        style: TextStyle(color: Color(0xFF9A8C7E)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) =>
                          _MenuDrinkTile(drink: _filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDrinkTile extends StatelessWidget {
  final DrinkModel drink;
  const _MenuDrinkTile({required this.drink});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DrinkDetailScreen(drink: drink)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1714),
          border: Border.all(color: const Color(0xFF2E2820)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(drink.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.name,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF0E8DC),
                    ),
                  ),
                  Text(
                    drink.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A8C7E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${drink.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC8965A),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                cart.addItem(drink);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${drink.name} added to cart'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF1A1714),
                  ),
                );
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x22C8965A),
                  border: Border.all(color: const Color(0x55C8965A)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFFC8965A),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}