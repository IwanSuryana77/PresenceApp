
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Dapatkan user ID dari user yang sedang login
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Dapatkan email user yang sedang login
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Dapatkan nama user dari Firestore atau email
  static Future<String> getCurrentUserName() async {
    final uid = getCurrentUserId();
    if (uid == null) return 'Unknown';

    try {
      // Coba ambil dari Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['name'] != null) {
        return doc.data()!['name'];
      }
    } catch (e) {
      print('Error getting user name from Firestore: $e');
    }

    // Fallback ke email
    return getCurrentUserEmail() ?? 'Unknown User';
  }

  /// Simpan profile user ke Firestore
  static Future<void> saveUserProfile({
    required String name,
    required String email,
  }) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // Cek apakah user sudah login
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Logout user
  static Future<void> logout() {
    return _auth.signOut();
  }
}
