import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/data/discogs_service.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/model/album_details.dart';
import 'package:trabalhomobile/screens/album_details_screen.dart';
import 'package:trabalhomobile/screens/cart_screen.dart';
import 'package:trabalhomobile/screens/store_screen.dart';

class FakeDiscogsService extends DiscogsService {
  @override
  Future<AlbumDetails> fetchAlbumDetails(int masterId) async => AlbumDetails(
    masterId: masterId,
    title: 'Details title',
    artists: [],
    genres: [],
    styles: [],
    tracklist: [],
  );
  final calls = <({String? query, String? genre})>[];
  final List<Album> results;
  final Map<String, List<Album>> genreResults;
  Future<List<Album>> Function(String? query, String? genre)? onFetch;

  FakeDiscogsService(this.results, {this.genreResults = const {}});

  @override
  Future<List<Album>> fetchAlbums({String? query, String? genre}) async {
    calls.add((query: query, genre: genre));
    if (onFetch != null) return onFetch!(query, genre);
    return genre == null ? results : genreResults[genre] ?? [];
  }
}

Album album(String title, int id, String genre) =>
    Album(title: title, image: '', genres: [genre], masterId: id);

Future<void> openStore(WidgetTester tester, FakeDiscogsService service) async {
  await tester.pumpWidget(
    RepositoryProvider<DiscogsService>.value(
      value: service,
      child: const MaterialApp(home: StoreScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> applyGenres(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.filter_list));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(CheckboxListTile, 'Rock'));
  await tester.pump();
  await tester.tap(find.widgetWithText(CheckboxListTile, 'Jazz'));
  await tester.pump();
  await tester.tap(find.text('Aplicar'));
  await tester.pumpAndSettle();
}

List<String> displayedTitles(WidgetTester tester) =>
    tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data!)
        .toList();

void main() {
  for (final add in [true, false]) {
    testWidgets(
      'Details retorna ao mesmo carrinho ${add ? 'com adições' : 'sem adições'}',
      (tester) async {
        final original = album('Artist - Album', 1, 'Rock');
        await openStore(tester, FakeDiscogsService([original]));
        await tester.tap(find.text('Album'));
        await tester.pumpAndSettle();
        expect(find.byType(AlbumDetailsScreen), findsOneWidget);
        expect(
          tester
              .widget<AlbumDetailsScreen>(find.byType(AlbumDetailsScreen))
              .album,
          same(original),
        );
        if (add) {
          for (var i = 0; i < 2; i++) {
            await tester.tap(find.text('Adicionar ao carrinho'));
            await tester.pump();
          }
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        if (add) {
          expect(
            find.descendant(of: find.byType(Badge), matching: find.text('2')),
            findsOneWidget,
          );
        } else {
          expect(find.byType(Badge), findsNothing);
        }
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        final cart = tester.widget<CartScreen>(find.byType(CartScreen)).cart;
        expect(cart, hasLength(add ? 2 : 0));
        expect(cart.every((item) => identical(item, original)), isTrue);
      },
    );
  }

  testWidgets('botão do card adiciona sem abrir Details', (tester) async {
    await openStore(tester, FakeDiscogsService([album('Album', 1, 'Rock')]));
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumDetailsScreen), findsNothing);
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );
  });
  testWidgets(
    'card separa álbum e artista, preservando gênero e título original',
    (tester) async {
      final original = album('Metallica - Master Of Puppets', 1, 'Rock');
      await openStore(tester, FakeDiscogsService([original]));
      expect(find.byType(Card), findsOneWidget);
      expect(displayedTitles(tester), ['Master Of Puppets']);
      expect(find.text('Metallica'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(original.title, 'Metallica - Master Of Puppets');
      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pump();
      expect(
        find.text('Metallica - Master Of Puppets adicionado ao carrinho!'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget,
      );
    },
  );

  testWidgets('card sem separador omite artista e mantém fallback de gênero', (
    tester,
  ) async {
    await openStore(
      tester,
      FakeDiscogsService([Album(title: 'Instrumental', image: '', genres: [])]),
    );
    expect(displayedTitles(tester), ['Instrumental']);
    final texts = tester
        .widgetList<Text>(
          find.descendant(of: find.byType(Card), matching: find.byType(Text)),
        )
        .map((text) => text.data);
    expect(texts, ['Instrumental', 'Sem gênero']);
  });

  testWidgets('card limita textos longos sem overflow em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final longArtist = List.filled(20, 'Artista').join(' ');
    final longTitle = List.filled(30, 'Álbum').join(' ');
    await openStore(
      tester,
      FakeDiscogsService([
        Album(
          title: '$longArtist - $longTitle',
          image: '',
          genres: List.filled(20, 'Rock'),
        ),
      ]),
    );
    final texts =
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(Card),
                matching: find.byType(Text),
              ),
            )
            .toList();
    expect(texts.map((text) => text.maxLines), [2, 1, 1]);
    expect(
      texts.every((text) => text.overflow == TextOverflow.ellipsis),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('carrinho vazio não exibe badge', (tester) async {
    await openStore(tester, FakeDiscogsService([]));
    expect(find.byType(Badge), findsNothing);
  });

  for (final repeated in [false, true]) {
    testWidgets('badge conta dois itens ${repeated ? 'iguais' : 'distintos'}', (
      tester,
    ) async {
      await openStore(
        tester,
        FakeDiscogsService([
          album('First', 1, 'Rock'),
          album('Second', 2, 'Pop'),
        ]),
      );
      await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
      await tester.pump();
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget,
      );
      await tester.tap(
        find.byIcon(Icons.add_shopping_cart).at(repeated ? 0 : 1),
      );
      await tester.pump();
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsOneWidget,
      );
    });
  }

  testWidgets('badge reflete remoções ao voltar do carrinho e some ao zerar', (
    tester,
  ) async {
    await openStore(tester, FakeDiscogsService([album('Album', 1, 'Rock')]));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pump();
    }
    for (final remaining in [1, 0]) {
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      if (remaining == 0) {
        expect(find.byType(Badge), findsNothing);
      } else {
        expect(
          find.descendant(of: find.byType(Badge), matching: find.text('1')),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('capa ausente usa placeholder de 72 por 72', (tester) async {
    await openStore(tester, FakeDiscogsService([album('Album', 1, 'Rock')]));
    final leading = tester.widget<ListTile>(find.byType(ListTile)).leading!;
    expect(tester.getSize(find.byWidget(leading)), const Size(72, 72));
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.titleAlignment, ListTileTitleAlignment.center);
    expect(
      tester
          .widget<ClipRRect>(
            find.descendant(
              of: find.byWidget(leading),
              matching: find.byType(ClipRRect),
            ),
          )
          .borderRadius,
      BorderRadius.circular(6),
    );
    expect(find.byIcon(Icons.album), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('falha de rede na capa usa placeholder sem quebrar tela', (
    tester,
  ) async {
    // The widget-test HTTP client rejects network requests with status 400.
    await openStore(
      tester,
      FakeDiscogsService([
        Album(
          title: 'Album',
          image: 'https://example.com/missing-cover.jpg',
          genres: ['Rock'],
        ),
      ]),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.album), findsOneWidget);
    expect(tester.takeException(), isNull);
    final leading = tester.widget<ListTile>(find.byType(ListTile)).leading!;
    expect(tester.getSize(find.byWidget(leading)), const Size(72, 72));
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    expect(find.text('Album'), findsOneWidget);
  });

  testWidgets('estado vazio mostra ícone, título e orientação', (tester) async {
    await openStore(tester, FakeDiscogsService([]));
    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
    expect(
      find.text('Tente outro artista, álbum ou remova os filtros.'),
      findsOneWidget,
    );
  });

  testWidgets('Aplicar confirma seleção somente ao confirmar o modal', (
    tester,
  ) async {
    final service = FakeDiscogsService(
      [album('Catalog', 1, 'Pop')],
      genreResults: {
        'Rock': [album('Rock album', 2, 'Rock')],
      },
    );
    await openStore(tester, service);
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Rock'));
    await tester.pump();
    expect(service.calls, hasLength(1));
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(service.calls.last.genre, 'Rock');
    expect(displayedTitles(tester), ['Rock album']);
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Rock'),
          )
          .value,
      isTrue,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  for (final dismissal in ['Cancelar', 'voltar', 'fora']) {
    testWidgets('$dismissal descarta seleção temporária', (tester) async {
      final service = FakeDiscogsService([album('Catalog', 1, 'Pop')]);
      await openStore(tester, service);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Rock'));
      await tester.pump();
      if (dismissal == 'Cancelar') {
        await tester.tap(find.text('Cancelar'));
      } else if (dismissal == 'voltar') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tapAt(const Offset(5, 5));
      }
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(service.calls, hasLength(1));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(service.calls.last, (query: null, genre: null));
      expect(displayedTitles(tester), ['Catalog']);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Rock'),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Cancelar preserva filtros previamente aplicados', (
    tester,
  ) async {
    final service = FakeDiscogsService(
      [],
      genreResults: {
        'Rock': [album('Rock album', 1, 'Rock')],
        'Jazz': [album('Jazz album', 2, 'Jazz')],
      },
    );
    await openStore(tester, service);
    await applyGenres(tester);
    final previousCalls = service.calls.length;
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Rock'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Pop'));
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(service.calls, hasLength(previousCalls));
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(service.calls.skip(previousCalls).map((call) => call.genre), [
      'Rock',
      'Jazz',
    ]);
    expect(displayedTitles(tester), ['Rock album', 'Jazz album']);
  });

  testWidgets('desmarcar tudo e Aplicar remove filtros mantendo texto atual', (
    tester,
  ) async {
    final service = FakeDiscogsService([
      album('Artist - Rock', 1, 'Rock'),
      album('Artist - Jazz', 2, 'Jazz'),
      album('Artist - Pop', 3, 'Pop'),
    ]);
    await openStore(tester, service);
    await tester.enterText(find.byType(TextField), 'Artist');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await applyGenres(tester);
    expect(displayedTitles(tester), ['Rock', 'Jazz']);
    await applyGenres(tester); // Toggles both applied genres off.
    expect(service.calls.last, (query: 'Artist', genre: null));
    expect(displayedTitles(tester), ['Rock', 'Jazz', 'Pop']);
  });

  testWidgets('debounce aguarda 450 ms sem apagar a lista', (tester) async {
    final service = FakeDiscogsService([album('Catalog', 1, 'Rock')]);
    await openStore(tester, service);
    await tester.enterText(find.byType(TextField), 'M');
    await tester.pump(const Duration(milliseconds: 449));
    expect(service.calls, hasLength(1));
    expect(displayedTitles(tester), ['Catalog']);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(service.calls, hasLength(2));
    expect(service.calls.last.query, 'M');
    await tester.pumpAndSettle();
  });

  testWidgets('digitação rápida reinicia debounce e faz uma única busca', (
    tester,
  ) async {
    final service = FakeDiscogsService([]);
    await openStore(tester, service);
    for (final text in ['M', 'Me', 'Meta']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 200));
      expect(service.calls, hasLength(1));
    }
    await tester.pump(const Duration(milliseconds: 250));
    expect(service.calls, hasLength(2));
    expect(service.calls.last.query, 'Meta');
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls, hasLength(2));
  });

  for (final useEnter in [true, false]) {
    testWidgets(
      '${useEnter ? 'Enter' : 'botão'} busca imediatamente e cancela debounce',
      (tester) async {
        final service = FakeDiscogsService([]);
        await openStore(tester, service);
        await tester.enterText(find.byType(TextField), 'Metallica');
        await tester.pump(const Duration(milliseconds: 100));
        if (useEnter) {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          await tester.tap(find.byIcon(Icons.search));
        }
        await tester.pump();
        expect(service.calls, hasLength(2));
        expect(service.calls.last.query, 'Metallica');
        await tester.pump(const Duration(seconds: 1));
        expect(service.calls, hasLength(2));
      },
    );
  }

  testWidgets('X aparece com texto, limpa e volta ao catálogo imediatamente', (
    tester,
  ) async {
    final service = FakeDiscogsService([album('Catalog', 1, 'Rock')]);
    await openStore(tester, service);
    expect(find.byIcon(Icons.clear), findsNothing);
    await tester.enterText(find.byType(TextField), 'Metallica');
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsOneWidget);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.byIcon(Icons.clear), findsNothing);
    expect(service.calls, hasLength(2));
    expect(service.calls.last, (query: null, genre: null));
    expect(displayedTitles(tester), ['Catalog']);
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls, hasLength(2));
  });

  testWidgets('X respeita gêneros aplicados e cancela debounce', (
    tester,
  ) async {
    final service = FakeDiscogsService(
      [],
      genreResults: {
        'Rock': [album('Rock album', 1, 'Rock')],
        'Jazz': [album('Jazz album', 2, 'Jazz')],
      },
    );
    await openStore(tester, service);
    await applyGenres(tester);
    await tester.enterText(find.byType(TextField), 'Metallica');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(displayedTitles(tester), ['Rock album', 'Jazz album']);
    expect(service.calls.skip(3).map((call) => call.genre), ['Rock', 'Jazz']);
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls, hasLength(5));
  });

  testWidgets('resposta antiga não sobrescreve a nova', (tester) async {
    final service = FakeDiscogsService([]);
    await openStore(tester, service);
    final old = Completer<List<Album>>();
    final latest = Completer<List<Album>>();
    service.onFetch =
        (query, _) => query == 'Metallica' ? old.future : latest.future;
    await tester.enterText(find.byType(TextField), 'Metallica');
    await tester.tap(find.byIcon(Icons.search));
    await tester.enterText(find.byType(TextField), 'Michael Jackson');
    await tester.tap(find.byIcon(Icons.search));
    latest.complete([album('Michael Jackson - Bad', 1, 'Pop')]);
    await tester.pump();
    old.complete([album('Metallica - Metallica', 2, 'Rock')]);
    await tester.pump();
    expect(displayedTitles(tester), ['Bad']);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'intenção invalida ${fails ? 'erro' : 'resposta'} antes do debounce',
      (tester) async {
        final service = FakeDiscogsService([]);
        await openStore(tester, service);
        final old = Completer<List<Album>>();
        service.onFetch =
            (query, _) async =>
                query == 'Old' ? old.future : [album('New', 1, 'Pop')];
        await tester.enterText(find.byType(TextField), 'Old');
        await tester.tap(find.byIcon(Icons.search));
        await tester.enterText(find.byType(TextField), 'New');
        if (fails) {
          old.completeError(Exception('old failure'));
        } else {
          old.complete([album('Old', 2, 'Rock')]);
        }
        await tester.pump(const Duration(milliseconds: 100));
        expect(service.calls, hasLength(2));
        expect(displayedTitles(tester), isEmpty);
        expect(find.byType(SnackBar), findsNothing);
        // An obsolete finally must not change loading even during debounce.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        expect(displayedTitles(tester), ['New']);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  }

  testWidgets('erro e finally antigos não afetam nova busca em loading', (
    tester,
  ) async {
    final service = FakeDiscogsService([]);
    await openStore(tester, service);
    final old = Completer<List<Album>>();
    final latest = Completer<List<Album>>();
    service.onFetch = (query, _) => query == 'Old' ? old.future : latest.future;
    await tester.enterText(find.byType(TextField), 'Old');
    await tester.tap(find.byIcon(Icons.search));
    await tester.enterText(find.byType(TextField), 'New');
    await tester.tap(find.byIcon(Icons.search));
    old.completeError(Exception('old failure'));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    latest.complete([album('New', 1, 'Rock')]);
    await tester.pump();
    expect(displayedTitles(tester), ['New']);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('X invalida requisição anterior em andamento', (tester) async {
    final service = FakeDiscogsService([]);
    await openStore(tester, service);
    final old = Completer<List<Album>>();
    service.onFetch =
        (query, _) async =>
            query == null ? [album('Catalog', 1, 'Rock')] : old.future;
    await tester.enterText(find.byType(TextField), 'Old');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    old.complete([album('Old', 2, 'Pop')]);
    await tester.pump();
    expect(displayedTitles(tester), ['Catalog']);
  });

  testWidgets('dispose cancela debounce pendente', (tester) async {
    final service = FakeDiscogsService([]);
    await openStore(tester, service);
    await tester.enterText(find.byType(TextField), 'Pending');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets('dispose ignora ${fails ? 'erro' : 'resposta'} HTTP pendente', (
      tester,
    ) async {
      final service = FakeDiscogsService([]);
      await openStore(tester, service);
      final pending = Completer<List<Album>>();
      service.onFetch = (_, _) => pending.future;
      await tester.enterText(find.byType(TextField), 'Pending');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpWidget(const SizedBox());
      if (fails) {
        pending.completeError(Exception('disposed'));
      } else {
        pending.complete([album('Pending', 1, 'Rock')]);
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('busca manual e gêneros preservam semântica OU', (tester) async {
    final service = FakeDiscogsService([
      album('Artist - Rock album', 1, 'Rock'),
      album('Artist - Jazz album', 2, 'Jazz'),
      album('Artist - Pop album', 3, 'Pop'),
    ]);
    await openStore(tester, service);
    await tester.enterText(find.byType(TextField), 'Artist');
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.calls, hasLength(1));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(service.calls.last.query, 'Artist');
    await applyGenres(tester);
    expect(displayedTitles(tester), ['Rock album', 'Jazz album']);
    expect(service.calls.every((call) => call.genre == null), isTrue);
  });

  testWidgets('intercala gêneros e deduplica por master após intercalar', (
    tester,
  ) async {
    final service = FakeDiscogsService(
      [],
      genreResults: {
        'Rock': [album('R0', 1, 'Rock'), album('Shared rock', 2, 'Rock')],
        'Jazz': [album('Shared jazz', 2, 'Jazz'), album('J1', 3, 'Jazz')],
      },
    );
    await openStore(tester, service);
    await applyGenres(tester);
    expect(displayedTitles(tester), ['R0', 'Shared jazz', 'J1']);
    expect(service.calls.map((call) => call.genre), [null, 'Rock', 'Jazz']);
  });

  testWidgets('deduplicação e nova busca não removem repetições do carrinho', (
    tester,
  ) async {
    final service = FakeDiscogsService([
      album('Artist - Album', 1, 'Rock'),
      album('Artist - Other spelling', 1, 'Rock'),
    ]);
    await openStore(tester, service);
    expect(displayedTitles(tester), ['Album']);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField), 'Artist');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();
    expect(displayedTitles(tester), ['Album', 'Album']);
    expect(find.text('Finalizar Compra (2 itens)'), findsOneWidget);
  });
}
