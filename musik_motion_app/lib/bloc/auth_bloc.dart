import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_service.dart';
import '../data/firebase_firestore_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthBloc(this._authService, this._firestoreService) : super(AuthInitial()) {
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>((e, emit) async {
      await _authService.logout();
      emit(AuthUnauthenticated());
    });
  }

  Future<void> _onRegister(AuthRegisterRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final cred = await _authService.register(e.email, e.password);
    if (cred != null) {
      await _firestoreService.saveUserData(
        uid: cred.user!.uid,
        name: e.name,
        lastName: e.lastName,
        email: e.email,
        address: e.address,
        city: e.city,
        state: e.state,
      );
      emit(AuthAuthenticated());
    } else {
      emit(AuthFailure('Falha no cadastro'));
    }
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final cred = await _authService.login(e.email, e.password);
    if (cred != null) {
      emit(AuthAuthenticated());
    } else {
      emit(AuthFailure('Email ou senha inválidos'));
    }
  }
}
