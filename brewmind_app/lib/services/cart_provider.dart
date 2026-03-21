import 'package:brewmind_app/models/drink_model.dart';
import 'package:flutter/material.dart';

class CartItem {
  final DrinkModel drink;
  int quantity;

  CartItem({required this.drink, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.values.fold(
    0,
    (sum, item) => sum + item.drink.price * item.quantity,
  );

  // Add a drink to cart
  void addItem(DrinkModel drink) {
    if (_items.containsKey(drink.drinkID)) {
      _items[drink.drinkID]!.quantity++;
    } else {
      _items[drink.drinkID] = CartItem(drink: drink);
    }
    notifyListeners();
  }

  // Remove one unit of a drink
  void removeItem(String drinkId) {
    if (!_items.containsKey(drinkId)) return;
    if (_items[drinkId]!.quantity > 1) {
      _items[drinkId]!.quantity--;
    } else {
      _items.remove(drinkId);
    }
    notifyListeners();
  }

  // Clear the whole cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderList() {
    return _items.values
        .map(
          (item) => {
            'drinkID': item.drink.drinkID,
            'name': item.drink.name,
            'quantity': item.quantity,
            'price': item.drink.price,
          },
        )
        .toList();
  }
}
