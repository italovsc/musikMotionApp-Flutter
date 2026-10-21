import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/screens/purchase_success_screen.dart';

void main() {
  testWidgets('sucesso apresenta conteúdo e ação explícita sem configurações', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PurchaseSuccessScreen()));
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('Compra concluída!'), findsOneWidget);
    expect(
      find.text('Obrigado por comprar com a Musik Motion.'),
      findsOneWidget,
    );
    expect(
      find.text('Esperamos que aproveite seus discos e muita música!'),
      findsOneWidget,
    );
    expect(find.text('Voltar ao início'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
      isFalse,
    );
  });

  testWidgets('sem voltar no AppBar e ação remove toda a pilha anterior', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Loja anterior')),
        routes: {
          '/cart': (_) => const Scaffold(body: Text('Carrinho anterior')),
          '/success': (_) => const PurchaseSuccessScreen(),
          '/navigation': (_) => const Scaffold(body: Text('Início destino')),
        },
      ),
    );
    navigatorKey.currentState!.pushNamed('/cart');
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pushNamed('/success');
    await tester.pumpAndSettle();
    expect(navigatorKey.currentState!.canPop(), isTrue);
    expect(find.byType(BackButton), findsNothing);
    await tester.tap(find.text('Voltar ao início'));
    await tester.pumpAndSettle();
    expect(find.text('Início destino'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(
      find.byType(PurchaseSuccessScreen, skipOffstage: false),
      findsNothing,
    );
    expect(find.text('Carrinho anterior', skipOffstage: false), findsNothing);
    expect(find.text('Loja anterior', skipOffstage: false), findsNothing);
  });

  testWidgets('tela pequena permite alcançar ação sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: PurchaseSuccessScreen()));
    await tester.ensureVisible(find.text('Voltar ao início'));
    await tester.pumpAndSettle();
    expect(find.text('Voltar ao início').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
