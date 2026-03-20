class UserModel {
  final String userID;
  final String name;
  final String email;
  final List<String> allergies; // e.g. ["milk", "nuts"]
  final String birthday; // ISO format: "1998-05-14"
  final int starPoints;

  UserModel({
    required this.userID,
    required this.name,
    required this.email,
    required this.allergies,
    required this.birthday,
    required this.starPoints,
  });

  // Create UserModel from Firestore document data
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userID: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      birthday: map['birthday'] ?? '',
      starPoints: map['starPoints'] ?? 0,
    );
  }

  // Convert UserModel to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'allergies': allergies,
      'birthday': birthday,
      'starPoints': starPoints,
    };
  }
}
