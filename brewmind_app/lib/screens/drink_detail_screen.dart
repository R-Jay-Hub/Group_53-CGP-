// ============================================================
// FILE: mobile-app/lib/screens/drink_detail_screen.dart
// SAVE TO: brewmind_app/lib/screens/drink_detail_screen.dart
// ============================================================
import 'package:brewmind_app/models/drink_model.dart';
import 'package:brewmind_app/services/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DrinkDetailScreen extends StatelessWidget {
  final DrinkModel drink;
  const DrinkDetailScreen({super.key, required this.drink});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0D0B),
        foregroundColor: const Color(0xFFF0E8DC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(drink.emoji, style: const TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(
              drink.name,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF0E8DC),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              drink.description,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF9A8C7E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _infoRow(
              'Price',
              'RM ${drink.price.toStringAsFixed(2)}',
              Color(0xFFC8965A),
            ),
            _infoRow('Category', drink.category, Color(0xFF7EB8A4)),
            _infoRow('Mood', drink.moodTag.toUpperCase(), Color(0xFFA89BC0)),
            if (drink.allergens.isNotEmpty)
              _infoRow(
                'Allergens',
                drink.allergens.join(', '),
                Color(0xFFD4856A),
              ),
            const SizedBox(height: 24),
            const Text(
              'INGREDIENTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A504A),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: drink.ingredients
                  .map(
                    (i) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1714),
                        border: Border.all(color: const Color(0xFF2E2820)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        i,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9A8C7E),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  cart.addItem(drink);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${drink.name} added to cart!'),
                      backgroundColor: const Color(0xFF1A1714),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8965A),
                  foregroundColor: const Color(0xFF1A1714),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9A8C7E)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
