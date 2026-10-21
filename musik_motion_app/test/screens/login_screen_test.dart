import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trabalhomobile/bloc/auth_bloc.dart';
import 'package:trabalhomobile/bloc/auth_event.dart';
import 'package:trabalhomobile/bloc/auth_state.dart';
import 'package:trabalhomobile/screens/login_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;
  late StreamController<AuthState> states;
  final email = find.byType(TextFormField).at(0);
  final password = find.byType(TextFormField).at(1);

  setUpAll(
    () => registerFallbackValue(AuthLoginRequested(email: '', password: '')),
  );
  setUp(() {
    bloc = MockAuthBloc();
    states = StreamController<AuthState>.broadcast();
    whenListen(bloc, states.stream, initialState: AuthUnauthenticated());
  });
  tearDown(() async {
    await states.close();
    await bloc.close();
  });

  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/register': (_) => const Scaffold(body: Text('Cadastro destino')),
            '/navigation': (_) => const Scaffold(body: Text('App destino')),
          },
        ),
      ),
    );
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(email, '  ana@example.com  ');
    await tester.enterText(password, '  senha sem trim  ');
  }

  testWidgets('cabeçalho e campos mantêm identidade e teclado de email', (
    tester,
  ) async {
    await openLogin(tester);
    expect(find.text('Musik Motion'), findsOneWidget);
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(
      find.text('Entre para continuar explorando seus discos.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.album), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).keyboardType,
      TextInputType.emailAddress,
    );
  });

  testWidgets('email e senha continuam obrigatórios', (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe o email'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets(
    'autovalidação inicia somente após tentativa e acompanha correções',
    (tester) async {
      await openLogin(tester);
      await tester.enterText(email, 'invalido');
      await tester.pump();
      expect(find.text('Informe um email válido'), findsNothing);
      expect(find.text('Informe a senha'), findsNothing);
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Informe um email válido'), findsOneWidget);
      await tester.enterText(email, 'ana@example.com');
      await tester.pump();
      expect(find.text('Informe um email válido'), findsNothing);
      await tester.enterText(email, 'invalido novamente');
      await tester.pump();
      expect(find.text('Informe um email válido'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    },
  );

  for (final index in [0, 1]) {
    testWidgets(
      'cadastro com campo $index focado não restaura foco ao voltar',
      (tester) async {
        await openLogin(tester);
        await tester.tap(find.byType(TextFormField).at(index));
        await tester.pump();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).at(index))
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(tester.testTextInput.isVisible, isTrue);
        await tester.ensureVisible(find.text('Criar conta'));
        await tester.tap(find.text('Criar conta'));
        await tester.pumpAndSettle();
        expect(find.text('Cadastro destino'), findsOneWidget);
        Navigator.of(tester.element(find.text('Cadastro destino'))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        for (final editable in tester.widgetList<EditableText>(
          find.byType(EditableText),
        )) {
          expect(editable.focusNode.hasFocus, isFalse);
        }
        expect(tester.testTextInput.isVisible, isFalse);
      },
    );
  }

  testWidgets('email inválido preserva validação', (tester) async {
    await openLogin(tester);
    await tester.enterText(email, 'invalido');
    await tester.enterText(password, 'senha');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe um email válido'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('olho alterna senha sem modificar o conteúdo', (tester) async {
    await openLogin(tester);
    await tester.enterText(password, ' senha ');
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      ' senha ',
    );
    await tester.tap(find.byTooltip('Ocultar senha'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
  });

  for (final submit in ['botão', 'done']) {
    testWidgets('$submit envia evento existente sem trim da senha', (
      tester,
    ) async {
      await openLogin(tester);
      await fill(tester);
      if (submit == 'botão') {
        await tester.tap(find.text('Entrar'));
      } else {
        await tester.testTextInput.receiveAction(TextInputAction.done);
      }
      final event =
          verify(() => bloc.add(captureAny())).captured.single
              as AuthLoginRequested;
      expect(event.email, 'ana@example.com');
      expect(event.password, '  senha sem trim  ');
    });
  }

  testWidgets('loading bloqueia botão e envio pelo teclado', (tester) async {
    await openLogin(tester);
    await fill(tester);
    await tester.tap(find.text('Entrar'));
    states.add(AuthLoading());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.tap(password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    verify(() => bloc.add(any())).called(1);
  });

  testWidgets('done inválido não envia e next avança foco', (tester) async {
    await openLogin(tester);
    await tester.tap(email);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Informe a senha'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('permite rolar com campo focado sem erro', (tester) async {
    await openLogin(tester);

    await tester.tap(email);
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
  testWidgets('Criar conta mantém rota de cadastro', (tester) async {
    await openLogin(tester);
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastro destino'), findsOneWidget);
  });

  testWidgets('falha mantém mensagem e sucesso mantém rota', (tester) async {
    await openLogin(tester);
    states.add(AuthFailure('Mensagem original'));
    await tester.pump();
    expect(find.text('Mensagem original'), findsOneWidget);
    states.add(AuthAuthenticated());
    await tester.pumpAndSettle();
    expect(find.text('App destino'), findsOneWidget);
  });

  testWidgets('tela pequena com teclado permite rolagem sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await openLogin(tester);
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Criar conta').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
