import 'package:brewmind_app/models/reservation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loyalty_service.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;
  final _loyaltyService = LoyaltyService();

  // Check available table

  Future<bool> isTableAvailable({
    required String date,
    required String time,
    required int tableNumber,
  }) async {
    final query = await _db
        .collection('reservations')
        .where('date', isEqualTo: date)
        .where('time', isEqualTo: time)
        .where('tableNumber', isEqualTo: tableNumber)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    return query.docs.isEmpty;
  }

  Future<String> createReservation({
    required String userId,
    required String date,
    required String time,
    required int tableNumber,
    required int partySize,
  }) async {
    final available = await isTableAvailable(
      date: date,
      time: time,
      tableNumber: tableNumber,
    );

    if (!available) {
      throw Exception(
        'Sorry, Table $tableNumber is already booked at $time on $date.',
      );
    }

    final docRef = await _db.collection('reservations').add({
      'userID': userId,
      'date': date,
      'time': time,
      'tableNumber': tableNumber,
      'partySize': partySize,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _loyaltyService.addPoints(userId, 5);

    return docRef.id;
  }

  Future<void> cancelReservation(String reservationId) async {
    await _db.collection('reservations').doc(reservationId).update({
      'status': 'cancelled',
    });
  }

  Future<List<ReservationModel>> getUserReservations(String userId) async {
    final query = await _db
        .collection('reservations')
        .where('userID', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
