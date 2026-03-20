class OrderModel {
  final String orderID;
  final String userID;
  final List<Map<String, dynamic>>
  drinkList; // [{drinkID, name, quantity, price}]
  final double totalPrice;
  final String status; // pending | preparing | ready | completed | cancelled
  final DateTime date;
  final String notes;

  OrderModel({
    required this.orderID,
    required this.userID,
    required this.drinkList,
    required this.totalPrice,
    required this.status,
    required this.date,
    this.notes = '',
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      orderID: id,
      userID: map['userID'] ?? '',
      drinkList: List<Map<String, dynamic>>.from(map['drinkList'] ?? []),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      date: map['date']?.toDate() ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'drinkList': drinkList,
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
    };
  }
}
