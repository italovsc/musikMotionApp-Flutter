import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/screens/cart_screen.dart';

void main() {
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

      expect(find.text('Metallica - Master of Puppets'), findsOneWidget);

      expect(find.text('Finalizar Compra (1 itens)'), findsOneWidget);

      expect(find.text('O carrinho está vazio!'), findsNothing);
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

      expect(find.text('O carrinho está vazio!'), findsOneWidget);
    });

    testWidgets('exibe mensagem quando carrinho inicia vazio', (tester) async {
      final cart = <Album>[];

      await tester.pumpWidget(MaterialApp(home: CartScreen(cart: cart)));

      expect(find.text('O carrinho está vazio!'), findsOneWidget);

      expect(find.textContaining('Finalizar Compra'), findsNothing);
    });
  });
}
