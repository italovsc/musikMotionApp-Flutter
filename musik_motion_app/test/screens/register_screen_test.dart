import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trabalhomobile/bloc/auth_bloc.dart';
import 'package:trabalhomobile/bloc/auth_event.dart';
import 'package:trabalhomobile/bloc/auth_state.dart';
import 'package:trabalhomobile/screens/register_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;
  late StreamController<AuthState> states;
  Finder field(int index) => find.byType(TextFormField).at(index);
  setUpAll(() => registerFallbackValue(AuthLogoutRequested()));
  setUp(() {
    bloc = MockAuthBloc();
    states = StreamController<AuthState>.broadcast();
    whenListen(bloc, states.stream, initialState: AuthUnauthenticated());
  });
  tearDown(() async {
    await states.close();
    await bloc.close();
  });

  Future<void> open(WidgetTester tester, {bool fromLogin = false}) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          home:
              fromLogin
                  ? Builder(
                    builder:
                        (context) => Scaffold(
                          body: TextButton(
                            onPressed:
                                () => Navigator.pushNamed(context, '/register'),
                            child: const Text('Login origem'),
                          ),
                        ),
                  )
                  : const RegisterScreen(),
          routes: {
            '/register': (_) => const RegisterScreen(),
            '/navigation': (_) => const Scaffold(body: Text('App destino')),
          },
        ),
      ),
    );
    if (fromLogin) {
      await tester.tap(find.text('Login origem'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> fill(WidgetTester tester) async {
    final values = [
      ' Ana ',
      ' Silva ',
      ' ana@example.com ',
      ' senha com espaços ',
      ' Rua A ',
      ' Cidade A ',
      ' MG ',
    ];
    for (var i = 0; i < values.length; i++) {
      await tester.ensureVisible(field(i));
      await tester.enterText(field(i), values[i]);
    }
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
  }

  testWidgets('identidade e seções com sete campos', (tester) async {
    await open(tester);
    expect(find.text('Musik Motion'), findsOneWidget);
    expect(find.byIcon(Icons.album), findsOneWidget);
    expect(find.text('Dados pessoais'), findsOneWidget);
    expect(
      find.text('Preencha seus dados para começar a explorar o catálogo.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(7));
    expect(find.text('Endereço'), findsWidgets);
  });

  testWidgets('todos os campos continuam obrigatórios', (tester) async {
    await open(tester);
    await submit(tester);
    for (final message in [
      'Informe o nome',
      'Informe o sobrenome',
      'Informe o email',
      'Informe a senha',
      'Informe o endereço',
      'Informe a cidade',
      'Informe o estado',
    ]) {
      expect(find.text(message), findsOneWidget);
    }
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('email inválido e senha curta preservam mensagens', (
    tester,
  ) async {
    await open(tester);
    await fill(tester);
    await tester.ensureVisible(field(2));
    await tester.enterText(field(2), 'invalido');
    await tester.ensureVisible(field(3));
    await tester.enterText(field(3), '12345');
    await submit(tester);
    expect(find.text('Informe um email válido'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 6 caracteres'),
      findsOneWidget,
    );
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('senha começa oculta e olho alterna sem alterar conteúdo', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(field(3));
    await tester.enterText(field(3), ' senha ');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Ocultar senha'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
      isTrue,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(3)).controller!.text,
      ' senha ',
    );
  });

  for (final useDone in [false, true]) {
    testWidgets(
      '${useDone ? 'done' : 'Criar conta'} mantém evento e senha intacta',
      (tester) async {
        await open(tester);
        await fill(tester);
        if (useDone) {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          await submit(tester);
        }
        final event =
            verify(() => bloc.add(captureAny())).captured.single
                as AuthRegisterRequested;
        expect(event.name, 'Ana');
        expect(event.lastName, 'Silva');
        expect(event.email, 'ana@example.com');
        expect(event.password, ' senha com espaços ');
        expect(event.address, 'Rua A');
        expect(event.city, 'Cidade A');
        expect(event.state, 'MG');
      },
    );
  }

  testWidgets('loading bloqueia botão e done', (tester) async {
    await open(tester);
    await fill(tester);
    await submit(tester);
    states.add(AuthLoading());
    await tester.pump();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.ensureVisible(field(6));
    await tester.tap(field(6));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    verify(() => bloc.add(any())).called(1);
  });

  testWidgets('Entrar volta ao Login existente', (tester) async {
    await open(tester, fromLogin: true);
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Login origem'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('next avança e done inválido não envia', (tester) async {
    await open(tester);
    await tester.tap(field(0));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(1))
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.ensureVisible(field(6));
    await tester.tap(field(6));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Informe o estado'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('tocar fora remove foco', (tester) async {
    await open(tester);
    await tester.tap(field(0));
    await tester.tap(find.text('Musik Motion'));
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isFalse,
    );
  });

  testWidgets('mensagem de falha e rota de sucesso são preservadas', (
    tester,
  ) async {
    await open(tester);
    states.add(AuthFailure('Falha original'));
    await tester.pump();
    expect(find.text('Falha original'), findsOneWidget);
    states.add(AuthAuthenticated());
    await tester.pumpAndSettle();
    expect(find.text('App destino'), findsOneWidget);
  });

  testWidgets('tela pequena com teclado permite alcançar botão sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await open(tester);
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.byType(ElevatedButton).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
