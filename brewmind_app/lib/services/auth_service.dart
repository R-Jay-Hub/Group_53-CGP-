import 'package:brewmind_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Get singleton instances of Firebase services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // REGISTER new user
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String birthday,
    required List<String> allergies,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user!.updateDisplayName(name);

      final user = UserModel(
        userID: cred.user!.uid,
        name: name,
        email: email,
        allergies: allergies,
        birthday: birthday,
        starPoints: 0,
      );

      await _db.collection('users').doc(cred.user!.uid).set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // Log out
  Future<void> logout() async {
    await _auth.signOut();
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // GET user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // UPDATE user profile
  Future<void> updateProfile({
    required String uid,
    String? name,
    List<String>? allergies,
    String? birthday,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (allergies != null) updates['allergies'] = allergies;
    if (birthday != null) updates['birthday'] = birthday;

    await _db.collection('users').doc(uid).update(updates);

    if (name != null) {
      await _auth.currentUser?.updateDisplayName(name);
    }
  }

  String _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Authentication error. Please try again.';
    }
  }
}
