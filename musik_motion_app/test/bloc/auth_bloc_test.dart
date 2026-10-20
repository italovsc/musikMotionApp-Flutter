import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trabalhomobile/bloc/auth_bloc.dart';
import 'package:trabalhomobile/bloc/auth_event.dart';
import 'package:trabalhomobile/bloc/auth_state.dart';
import 'package:trabalhomobile/data/auth_service.dart';
import 'package:trabalhomobile/data/firebase_firestore_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockFirestoreService extends Mock implements FirestoreService {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthService authService;
  late MockFirestoreService firestoreService;

  setUp(() {
    authService = MockAuthService();
    firestoreService = MockFirestoreService();

    when(() => authService.currentUser).thenReturn(null);
  });

  test('estado inicial é AuthUnauthenticated quando não há usuário logado', () {
    final bloc = AuthBloc(authService, firestoreService);

    expect(bloc.state, isA<AuthUnauthenticated>());

    bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'emite AuthLoading e AuthAuthenticated quando login funciona',
    build: () {
      final credential = MockUserCredential();

      when(
        () => authService.login(any(), any()),
      ).thenAnswer((_) async => credential);

      return AuthBloc(authService, firestoreService);
    },
    act: (bloc) {
      bloc.add(
        AuthLoginRequested(email: 'teste@email.com', password: '123456'),
      );
    },
    expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
  );

  blocTest<AuthBloc, AuthState>(
    'emite AuthLoading e AuthAuthenticated quando cadastro é concluído',
    build: () {
      final credential = MockUserCredential();
      final user = MockUser();

      when(() => user.uid).thenReturn('uid-teste');

      when(() => credential.user).thenReturn(user);

      when(
        () => authService.register('novo@email.com', '123456'),
      ).thenAnswer((_) async => credential);

      when(
        () => firestoreService.saveUserData(
          uid: 'uid-teste',
          name: 'Italo',
          lastName: 'Victor',
          email: 'novo@email.com',
          address: 'Rua Teste',
          city: 'Belo Horizonte',
          state: 'MG',
        ),
      ).thenAnswer((_) async {});

      return AuthBloc(authService, firestoreService);
    },
    act: (bloc) {
      bloc.add(
        AuthRegisterRequested(
          name: 'Italo',
          lastName: 'Victor',
          email: 'novo@email.com',
          password: '123456',
          address: 'Rua Teste',
          city: 'Belo Horizonte',
          state: 'MG',
        ),
      );
    },
    expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    verify: (_) {
      verify(
        () => firestoreService.saveUserData(
          uid: 'uid-teste',
          name: 'Italo',
          lastName: 'Victor',
          email: 'novo@email.com',
          address: 'Rua Teste',
          city: 'Belo Horizonte',
          state: 'MG',
        ),
      ).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emite AuthFailure quando cadastro falha no Authentication',
    build: () {
      when(
        () => authService.register('existente@email.com', '123456'),
      ).thenThrow(const AuthServiceException('Este email já está cadastrado.'));

      return AuthBloc(authService, firestoreService);
    },
    act: (bloc) {
      bloc.add(
        AuthRegisterRequested(
          name: 'Italo',
          lastName: 'Victor',
          email: 'existente@email.com',
          password: '123456',
          address: 'Rua Teste',
          city: 'Belo Horizonte',
          state: 'MG',
        ),
      );
    },
    expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    verify: (bloc) {
      final state = bloc.state;

      expect(state, isA<AuthFailure>());

      expect((state as AuthFailure).message, 'Este email já está cadastrado.');

      verifyNever(
        () => firestoreService.saveUserData(
          uid: any(named: 'uid'),
          name: any(named: 'name'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          state: any(named: 'state'),
        ),
      );
    },
  );

  blocTest<AuthBloc, AuthState>(
    'remove usuário criado quando Firestore falha durante cadastro',
    build: () {
      final credential = MockUserCredential();
      final user = MockUser();

      when(() => user.uid).thenReturn('uid-teste');
      when(() => credential.user).thenReturn(user);

      when(
        () => authService.register('novo@email.com', '123456'),
      ).thenAnswer((_) async => credential);

      when(
        () => firestoreService.saveUserData(
          uid: 'uid-teste',
          name: 'Italo',
          lastName: 'Victor',
          email: 'novo@email.com',
          address: 'Rua Teste',
          city: 'Belo Horizonte',
          state: 'MG',
        ),
      ).thenThrow(Exception('Erro no Firestore'));

      when(() => authService.deleteCurrentUser()).thenAnswer((_) async {});

      return AuthBloc(authService, firestoreService);
    },
    act: (bloc) {
      bloc.add(
        AuthRegisterRequested(
          name: 'Italo',
          lastName: 'Victor',
          email: 'novo@email.com',
          password: '123456',
          address: 'Rua Teste',
          city: 'Belo Horizonte',
          state: 'MG',
        ),
      );
    },
    expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    verify: (bloc) {
      verify(() => authService.deleteCurrentUser()).called(1);

      final state = bloc.state;

      expect(state, isA<AuthFailure>());

      expect(
        (state as AuthFailure).message,
        'Não foi possível salvar os dados do cadastro. Tente novamente.',
      );
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emite AuthLoading e AuthFailure quando login falha',
    build: () {
      when(
        () => authService.login(any(), any()),
      ).thenThrow(const AuthServiceException('Email ou senha inválidos.'));

      return AuthBloc(authService, firestoreService);
    },
    act: (bloc) {
      bloc.add(
        AuthLoginRequested(email: 'teste@email.com', password: 'senha-errada'),
      );
    },
    expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    verify: (bloc) {
      final state = bloc.state;

      expect(state, isA<AuthFailure>());

      expect((state as AuthFailure).message, 'Email ou senha inválidos.');
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emite AuthUnauthenticated ao realizar logout',
    build: () {
      when(() => authService.logout()).thenAnswer((_) async {});

      return AuthBloc(authService, firestoreService);
    },
    seed: () => AuthAuthenticated(),
    act: (bloc) {
      bloc.add(AuthLogoutRequested());
    },
    expect: () => [isA<AuthUnauthenticated>()],
  );
}
