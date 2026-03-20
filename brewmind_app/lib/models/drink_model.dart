class DrinkModel {
  final String drinkID;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> allergens; // e.g. ["milk", "gluten"]
  final double price;
  final String moodTag; // happy | relaxed | stressed | tired | energetic
  final String category; // Coffee | Tea | Smoothie | etc.
  final String emoji;
  final bool available;
  final Map<String, dynamic> nutrition; // {calories, caffeine, fat, sugar}

  DrinkModel({
    required this.drinkID,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.allergens,
    required this.price,
    required this.moodTag,
    required this.category,
    required this.emoji,
    required this.available,
    required this.nutrition,
  });

  factory DrinkModel.fromMap(Map<String, dynamic> map, String id) {
    return DrinkModel(
      drinkID: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      allergens: List<String>.from(map['allergens'] ?? []),
      price: (map['price'] ?? 0.0).toDouble(),
      moodTag: map['moodTag'] ?? '',
      category: map['category'] ?? '',
      emoji: map['emoji'] ?? '☕',
      available: map['available'] ?? true,
      nutrition: Map<String, dynamic>.from(map['nutrition'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'allergens': allergens,
      'price': price,
      'moodTag': moodTag,
      'category': category,
      'emoji': emoji,
      'available': available,
      'nutrition': nutrition,
    };
  }
}
