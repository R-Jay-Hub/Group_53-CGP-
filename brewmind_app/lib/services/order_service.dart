import 'package:brewmind_app/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loyalty_service.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _loyaltyService = LoyaltyService();

  Future<String> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> drinkList,
    required double totalPrice,
    String notes = '',
  }) async {
    try {
      print('📦 Placing order for user: $userId');
      print('📦 Items: $drinkList');
      print('📦 Total: RM $totalPrice');

      final docRef = await _db.collection('orders').add({
        'userID': userId,
        'drinkList': drinkList,
        'totalPrice': totalPrice,
        'status': 'pending',
        'notes': notes,
        'date': FieldValue.serverTimestamp(),
      });

      print('✅ Order saved to Firebase! ID: ${docRef.id}');

      await _loyaltyService.addPoints(userId, 10);
      print('⭐ +10 points awarded to $userId');

      return docRef.id;
    } catch (e) {
      print('❌ Order failed: $e');
      rethrow;
    }
  }

  // Get user order history
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final query = await _db
          .collection('orders')
          .where('userID', isEqualTo: userId)
          .get();

      final orders = query.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      orders.sort((a, b) => b.date.compareTo(a.date));
      return orders;
    } catch (e) {
      print('❌ getUserOrders error: $e');
      return [];
    }
  }

  Stream<List<OrderModel>> getUserOrdersStream(String userId) {
    return _db
        .collection('orders')
        .where('userID', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.date.compareTo(a.date));
          return orders;
        });
  }
}
