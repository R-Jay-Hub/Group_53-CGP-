import 'package:brewmind_app/models/drink_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DrinkService {
  final _db = FirebaseFirestore.instance;

  // Get ALL available drinks
  Future<List<DrinkModel>> getAllDrinks() async {
    final query = await _db
        .collection('drinks')
        .where('available', isEqualTo: true)
        .get();

    return query.docs
        .map((doc) => DrinkModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get drinks by mood

  Future<List<DrinkModel>> getDrinksByMood(String mood) async {
    final query = await _db
        .collection('drinks')
        .where('moodTag', isEqualTo: mood)
        .where('available', isEqualTo: true)
        .get();

    return query.docs
        .map((doc) => DrinkModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get drinks by allergies

  Future<List<DrinkModel>> getDrinksSafe(List<String> userAllergens) async {
    final all = await getAllDrinks();
    if (userAllergens.isEmpty) return all;

    return all.where((drink) {
      return !drink.allergens.any((a) => userAllergens.contains(a));
    }).toList();
  }

  Future<List<DrinkModel>> getRecommendations(
    String mood,
    List<String> userAllergens,
  ) async {
    final moodDrinks = await getDrinksByMood(mood);
    if (userAllergens.isEmpty) return moodDrinks;

    return moodDrinks.where((drink) {
      return !drink.allergens.any((a) => userAllergens.contains(a));
    }).toList();
  }

  Future<DrinkModel?> getDrinkById(String drinkId) async {
    final doc = await _db.collection('drinks').doc(drinkId).get();
    if (doc.exists) {
      return DrinkModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}