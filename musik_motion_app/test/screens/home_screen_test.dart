import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trabalhomobile/bloc/auth_bloc.dart';
import 'package:trabalhomobile/bloc/auth_event.dart';
import 'package:trabalhomobile/bloc/auth_state.dart';
import 'package:trabalhomobile/data/discogs_service.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/navigation_wrapper.dart';
import 'package:trabalhomobile/screens/home_screen.dart';
import 'package:trabalhomobile/screens/store_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class EmptyDiscogsService extends DiscogsService {
  @override
  Future<List<Album>> fetchAlbums({String? query, String? genre}) async => [];
}

void main() {
  testWidgets(
    'Home apresenta identidade, introdução, CTA e recursos sem configurações',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(onExploreCatalog: () {})),
      );
      expect(find.text('Musik Motion'), findsOneWidget);
      expect(
        find.text('Encontre discos por artista ou álbum e monte seu carrinho.'),
        findsOneWidget,
      );
      expect(find.text('Explorar catálogo'), findsOneWidget);
      expect(find.text('Busque seus favoritos'), findsOneWidget);
      expect(find.text('Por artista ou álbum'), findsOneWidget);
      expect(find.text('Explore por gênero'), findsOneWidget);
      expect(find.text('Descubra diferentes estilos'), findsOneWidget);
      expect(find.text('Monte seu carrinho'), findsOneWidget);
      expect(find.text('Adicione os discos que encontrar'), findsOneWidget);
      expect(find.byIcon(Icons.album), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Card), matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
    },
  );

  testWidgets('CTA solicita abertura do catálogo', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(onExploreCatalog: () => calls++)),
    );
    await tester.tap(find.text('Explorar catálogo'));
    expect(calls, 1);
  });

  testWidgets('CTA seleciona aba Loja sem empilhar rota', (tester) async {
    final auth = MockAuthBloc();
    when(() => auth.state).thenReturn(AuthAuthenticated());
    addTearDown(auth.close);
    await tester.pumpWidget(
      RepositoryProvider<DiscogsService>.value(
        value: EmptyDiscogsService(),
        child: BlocProvider<AuthBloc>.value(
          value: auth,
          child: const MaterialApp(home: NavigationWrapper()),
        ),
      ),
    );
    await tester.tap(find.text('Explorar catálogo'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreScreen), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );
    expect(
      Navigator.of(tester.element(find.byType(StoreScreen))).canPop(),
      isFalse,
    );
    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Home rola em tela pequena sem overflow', (tester) async {
    tester.view.physicalSize = const Size(280, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(onExploreCatalog: () {})),
    );
    await tester.ensureVisible(find.text('Adicione os discos que encontrar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Adicione os discos que encontrar').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
