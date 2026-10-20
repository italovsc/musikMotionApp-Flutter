import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/screens/cart_screen.dart';

void main() {
  testWidgets('ocorrências iguais são independentes ao remover pelo botão', (
    tester,
  ) async {
    final item = Album(title: 'Artist - Album', image: '', genres: []);
    final cart = [item, item];
    await tester.pumpWidget(MaterialApp(home: CartScreen(cart: cart)));
    expect(find.text('Finalizar Compra (2 itens)'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(cart, [item]);
    expect(find.text('Album'), findsOneWidget);
    expect(find.text('Finalizar Compra (1 itens)'), findsOneWidget);
  });

  testWidgets('gesto remove item e atualiza quantidade até esvaziar', (
    tester,
  ) async {
    final cart = [
      Album(title: 'Artist - First', image: '', genres: []),
      Album(title: 'Artist - Second', image: '', genres: []),
    ];
    await tester.pumpWidget(MaterialApp(home: CartScreen(cart: cart)));
    await tester.drag(find.byType(Dismissible).first, const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(cart.single.title, 'Artist - Second');
    expect(find.text('Finalizar Compra (1 itens)'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('Artist - Second-0')),
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    expect(cart, isEmpty);
    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    expect(find.textContaining('Finalizar Compra'), findsNothing);
  });

  testWidgets('imagem com erro usa placeholder sem alterar dimensões', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cart: [
            Album(
              title: 'Album',
              image: 'https://example.com/cart-cover.jpg',
              genres: [],
            ),
          ],
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.album), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    final leading = tester.widget<ListTile>(find.byType(ListTile)).leading!;
    expect(tester.getSize(find.byWidget(leading)), const Size(72, 72));
    expect(tester.takeException(), isNull);
  });

  testWidgets('textos longos não causam overflow em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final text = List.filled(30, 'Longo').join(' ');
    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cart: [
            Album(title: '$text - $text', image: '', genres: [text]),
          ],
        ),
      ),
    );
    final texts = tester.widgetList<Text>(
      find.descendant(of: find.byType(Card), matching: find.byType(Text)),
    );
    expect(texts.map((text) => text.maxLines), [2, 1, 1]);
    expect(
      texts.every((text) => text.overflow == TextOverflow.ellipsis),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('finalização mantém rota atual', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(cart: [Album(title: 'Album', image: '', genres: [])]),
        routes: {
          '/success': (_) => const Scaffold(body: Text('Success route')),
        },
      ),
    );
    await tester.tap(find.text('Finalizar Compra (1 itens)'));
    await tester.pumpAndSettle();
    expect(find.text('Success route'), findsOneWidget);
  });

  group('CartScreen', () {
    testWidgets('exibe álbum presente no carrinho', (tester) async {
      final cart = [
        Album(
          title: 'Metallica - Master of Puppets',
          image: '',
          genres: ['Rock'],
        ),
      ];

      await tester.pumpWidget(MaterialApp(home: CartScreen(cart: cart)));

      expect(find.text('Master of Puppets'), findsOneWidget);
      expect(find.text('Metallica'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.album), findsOneWidget);
      final leading = tester.widget<ListTile>(find.byType(ListTile)).leading!;
      expect(tester.getSize(find.byWidget(leading)), const Size(72, 72));

      expect(find.text('Finalizar Compra (1 itens)'), findsOneWidget);

      expect(find.text('Seu carrinho está vazio'), findsNothing);
    });

    testWidgets('remove álbum ao tocar no botão de excluir', (tester) async {
      final cart = [
        Album(title: 'Thriller', image: '', genres: ['Pop']),
      ];

      await tester.pumpWidget(MaterialApp(home: CartScreen(cart: cart)));

      expect(find.text('Thriller'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));

      await tester.pump();

      expect(cart, isEmpty);

      expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    });

    testWidgets('exibe mensagem quando carrinho inicia vazio', (tester) async {
      final cart = <Album>[];

      await tester.pumpWidget(MaterialApp(home: CartScreen(cart: cart)));

      expect(find.text('Seu carrinho está vazio'), findsOneWidget);

      expect(find.textContaining('Finalizar Compra'), findsNothing);
    });
  });
}
