
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
}
