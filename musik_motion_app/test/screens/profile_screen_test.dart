import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trabalhomobile/bloc/auth_bloc.dart';
import 'package:trabalhomobile/bloc/auth_event.dart';
import 'package:trabalhomobile/bloc/auth_state.dart';
import 'package:trabalhomobile/data/auth_service.dart';
import 'package:trabalhomobile/data/firebase_firestore_service.dart';
import 'package:trabalhomobile/screens/profile_screen.dart';

class MockAuthService extends Mock implements AuthService {}

class MockFirestoreService extends Mock implements FirestoreService {}

class MockUser extends Mock implements User {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthService auth;
  late MockFirestoreService firestore;
  late MockAuthBloc bloc;
  late Map<String, dynamic> data;

  setUpAll(() => registerFallbackValue(AuthLogoutRequested()));
  setUp(() {
    auth = MockAuthService();
    firestore = MockFirestoreService();
    bloc = MockAuthBloc();
    final user = MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    data = {
      'name': 'Ana',
      'lastName': 'Silva',
      'email': 'ana@example.com',
      'address': 'Rua das Flores',
      'city': 'Belo Horizonte',
      'state': 'MG',
    };
    when(
      () => firestore.getUserData('user-1'),
    ).thenAnswer((_) async => Map.of(data));
    when(
      () => firestore.updateUserField(
        uid: any(named: 'uid'),
        field: any(named: 'field'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      data[invocation.namedArguments[#field] as String] =
          invocation.namedArguments[#value];
    });
  });
  tearDown(() => bloc.close());

  Future<void> openProfile(
    WidgetTester tester, {
    bool settle = true,
    bool withNavigation = false,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthService>.value(value: auth),
          RepositoryProvider<FirestoreService>.value(value: firestore),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp(
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
            home:
                withNavigation
                    ? Scaffold(
                      body: const ProfileScreen(),
                      bottomNavigationBar: BottomNavigationBar(
                        items: const [
                          BottomNavigationBarItem(
                            icon: Icon(Icons.home),
                            label: 'Casa',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.store),
                            label: 'Loja',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.person),
                            label: 'Usuário',
                          ),
                        ],
                      ),
                    )
                    : const ProfileScreen(),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('cabeçalho e seções exibem dados com email somente leitura', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Dados pessoais'), findsOneWidget);
    for (final label in ['Nome', 'Sobrenome', 'Cidade', 'Estado']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Endereço'), findsNWidgets(2));
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(5));
    expect(find.byTooltip('Editar email'), findsNothing);
    expect(
      find.ancestor(
        of: find.text('ana@example.com'),
        matching: find.byType(ListTile),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.logout),
      ),
      findsNothing,
    );
  });

  for (final entry
      in {
        'nome': 'name',
        'sobrenome': 'lastName',
        'endereço': 'address',
        'cidade': 'city',
        'estado': 'state',
      }.entries) {
    testWidgets('editar ${entry.key} mantém atualização e recarregamento', (
      tester,
    ) async {
      await openProfile(tester);
      final edit = find.byTooltip('Editar ${entry.key}');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        data[entry.value],
      );
      await tester.enterText(find.byType(TextField), '  Atualizado  ');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      verify(
        () => firestore.updateUserField(
          uid: 'user-1',
          field: entry.value,
          value: 'Atualizado',
        ),
      ).called(1);
      verify(() => firestore.getUserData('user-1')).called(2);
      expect(find.text('Atualizado'), findsOneWidget);
    });
  }

  testWidgets('cancelar e valor vazio não persistem alterações', (
    tester,
  ) async {
    await openProfile(tester);
    await tester.tap(find.byTooltip('Editar nome'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(
      () => firestore.updateUserField(
        uid: any(named: 'uid'),
        field: any(named: 'field'),
        value: any(named: 'value'),
      ),
    );
    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('Sair da conta mantém evento de logout', (tester) async {
    await openProfile(tester);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    final event = verify(() => bloc.add(captureAny())).captured.single;
    expect(event, isA<AuthLogoutRequested>());
  });

  testWidgets('logout continua disponível durante carregamento', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>?>();
    when(
      () => firestore.getUserData('user-1'),
    ).thenAnswer((_) => pending.future);
    await openProfile(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Sair da conta'));
    expect(
      verify(() => bloc.add(captureAny())).captured.single,
      isA<AuthLogoutRequested>(),
    );
    pending.complete(data);
    await tester.pumpAndSettle();
  });

  testWidgets('perfil cabe com navegação inferior em tela normal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await openProfile(tester, withNavigation: true);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(position.maxScrollExtent, 0);
    expect(find.text('Sair da conta').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fonte ampliada mantém rolagem e acesso ao logout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openProfile(tester, withNavigation: true, textScale: 2);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dados longos em tela pequena não causam overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    data.updateAll((key, value) => List.filled(20, value).join(' '));
    await openProfile(tester);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
