import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observar mudanças no estado de autenticação
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Registrar usuário com email e senha
  Future<UserCredential?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Erro ao registrar: $e');
      return null;
    }
  }

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String lastName,
    required String email,
    required String address,
    required String city,
    required String state,
  }) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    await userDoc.set({
      'name': name,
      'lastName': lastName,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'createdAt': Timestamp.now(),
    });
  }


  // Login com email e senha
  Future<UserCredential?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Erro ao fazer login: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Obter usuário atual
  User? get currentUser => _auth.currentUser;
}
