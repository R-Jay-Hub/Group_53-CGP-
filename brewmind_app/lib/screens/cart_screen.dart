import 'package:brewmind_app/screens/order_history_screen.dart';
import 'package:brewmind_app/services/cart_provider.dart';
import 'package:brewmind_app/services/order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (ctx, cart, _) => Scaffold(
        backgroundColor: const Color(0xFF0F0D0B),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Cart',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF0E8DC),
                      ),
                    ),
                    if (cart.items.isNotEmpty)
                      TextButton(
                        onPressed: cart.clearCart,
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: Color(0xFFD4856A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: cart.items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🛒', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                color: Color(0xFF9A8C7E),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Add drinks from the menu!',
                              style: TextStyle(
                                color: Color(0xFF5A504A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: cart.items.values
                            .map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1714),
                                  border: Border.all(
                                    color: const Color(0xFF2E2820),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      item.drink.emoji,
                                      style: const TextStyle(fontSize: 30),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.drink.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFFF0E8DC),
                                            ),
                                          ),
                                          Text(
                                            'Rs ${item.drink.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFFC8965A),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Color(0xFF9A8C7E),
                                            size: 20,
                                          ),
                                          onPressed: () => cart.removeItem(
                                            item.drink.drinkID,
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            color: Color(0xFFF0E8DC),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFFC8965A),
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              cart.addItem(item.drink),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              if (cart.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF9A8C7E),
                            ),
                          ),
                          Text(
                            'Rs ${cart.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC8965A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _placeOrder(context, cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC8965A),
                            foregroundColor: const Color(0xFF1A1714),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Place Order (+10 pts)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF1A1714),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFC8965A)),
            SizedBox(width: 16),
            Text(
              'Placing order...',
              style: TextStyle(color: Color(0xFFF0E8DC)),
            ),
          ],
        ),
      ),
    );

    try {
      final drinkList = cart.items.values
          .map(
            (item) => {
              'drinkID': item.drink.drinkID,
              'name': item.drink.name,
              'emoji': item.drink.emoji,
              'quantity': item.quantity,
              'price': item.drink.price,
            },
          )
          .toList();

      final orderService = OrderService();

      final orderId = await orderService.placeOrder(
        userId: uid,
        drinkList: drinkList,
        totalPrice: cart.totalPrice,
        notes: '',
      );

      Navigator.pop(context);

      cart.clearCart();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1714),
          title: const Text(
            'Order Placed! ☕',
            style: TextStyle(
              color: Color(0xFFF0E8DC),
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your order has been sent to the café!',
                style: TextStyle(color: Color(0xFFF0E8DC), fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF231F1B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E2820)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: \${orderId.substring(0, 8)}…',
                      style: const TextStyle(
                        fontFamily: 'DM Mono',
                        color: Color(0xFF9A8C7E),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Status: Pending',
                      style: TextStyle(color: Color(0xFFF4C430), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '⭐ +10 Star Points awarded!',
                      style: TextStyle(color: Color(0xFFC8965A), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We will notify you when your order is ready!',
                style: TextStyle(color: Color(0xFF9A8C7E), fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF9A8C7E)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
              child: const Text(
                'View Orders →',
                style: TextStyle(
                  color: Color(0xFFC8965A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1714),
          title: const Text(
            'Order Failed ❌',
            style: TextStyle(
              color: Color(0xFFD4856A),
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          content: Text(
            'Could not place order:\n\${e.toString()}',
            style: const TextStyle(color: Color(0xFF9A8C7E), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFC8965A)),
              ),
            ),
          ],
        ),
      );
    }
  }
}
