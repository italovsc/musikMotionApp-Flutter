import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_service.dart';
import '../data/firebase_firestore_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthBloc(AuthService authService, FirestoreService firestoreService)
    : _authService = authService,
      _firestoreService = firestoreService,
      super(
        authService.currentUser != null
            ? AuthAuthenticated()
            : AuthUnauthenticated(),
      ) {
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLoginRequested>(_onLogin);

    on<AuthLogoutRequested>((event, emit) async {
      await _authService.logout();
      emit(AuthUnauthenticated());
    });
  }

  Future<void> _onRegister(
    AuthRegisterRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final credential = await _authService.register(e.email, e.password);

      final user = credential.user;

      if (user == null) {
        emit(AuthFailure('Não foi possível concluir o cadastro.'));
        return;
      }

      try {
        await _firestoreService.saveUserData(
          uid: user.uid,
          name: e.name,
          lastName: e.lastName,
          email: e.email,
          address: e.address,
          city: e.city,
          state: e.state,
        );

        emit(AuthAuthenticated());
      } catch (_) {
        try {
          await _authService.deleteCurrentUser();
        } catch (_) {
          await _authService.logout();
        }

        emit(
          AuthFailure(
            'Não foi possível salvar os dados do cadastro. Tente novamente.',
          ),
        );
      }
    } on AuthServiceException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(
        AuthFailure('Não foi possível realizar o cadastro. Tente novamente.'),
      );
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
