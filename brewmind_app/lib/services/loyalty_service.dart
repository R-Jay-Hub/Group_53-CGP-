import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyService {
  final _db = FirebaseFirestore.instance;

  Future<void> addPoints(String userId, int points) async {
    await _db.collection('users').doc(userId).update({
      'starPoints': FieldValue.increment(points),
    });

    final lbRef = _db.collection('leaderboard').doc(userId);
    final snap = await lbRef.get();

    if (snap.exists) {
      await lbRef.update({
        'points': FieldValue.increment(points),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      final userDoc = await _db.collection('users').doc(userId).get();
      await lbRef.set({
        'userID': userId,
        'name': userDoc.data()?['name'] ?? 'Unknown',
        'points': points,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final query = await _db
        .collection('leaderboard')
        .orderBy('points', descending: true)
        .limit(20)
        .get();

    return query.docs.asMap().entries.map((entry) {
      return {'rank': entry.key + 1, ...entry.value.data()};
    }).toList();
  }

  Future<int> getUserPoints(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['starPoints'] ?? 0;
  }

  Future<int> getUserRank(String userId) async {
    final leaderboard = await getLeaderboard();
    final idx = leaderboard.indexWhere((e) => e['userID'] == userId);
    return idx == -1 ? 99 : idx + 1;
  }
}