import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String lastName,
    required String email,
    required String address,
    required String city,
    required String state,
  }) {
    return _db.collection('users').doc(uid).set({
      'name': name,
      'lastName': lastName,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  Future<void> updateUserField({
    required String uid,
    required String field,
    required String value,
  }) {
    return _db.collection('users').doc(uid).update({field: value});
  }
}
