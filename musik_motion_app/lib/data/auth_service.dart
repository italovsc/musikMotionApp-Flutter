import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observar mudanças no estado de autenticação
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Registrar usuário com email e senha
  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw const AuthServiceException('Este email já está cadastrado.');

        case 'invalid-email':
          throw const AuthServiceException('Informe um email válido.');

        case 'weak-password':
          throw const AuthServiceException(
            'A senha deve ter pelo menos 6 caracteres.',
          );

        case 'network-request-failed':
          throw const AuthServiceException(
            'Não foi possível conectar. Verifique sua internet.',
          );

        case 'too-many-requests':
          throw const AuthServiceException(
            'Muitas tentativas. Tente novamente mais tarde.',
          );

        case 'operation-not-allowed':
          throw const AuthServiceException(
            'O cadastro por email e senha não está disponível.',
          );

        default:
          throw const AuthServiceException(
            'Não foi possível realizar o cadastro. Tente novamente.',
          );
      }
    }
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

  // Excluir usuário atual
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;

    if (user != null) {
      await user.delete();
    }
  }

  // Obter usuário atual
  User? get currentUser => _auth.currentUser;
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);
}
