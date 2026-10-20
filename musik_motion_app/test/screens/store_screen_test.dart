import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/data/discogs_service.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/screens/store_screen.dart';

class FakeDiscogsService extends DiscogsService {
  final calls = <({String? query, String? genre})>[];
  final List<Album> results;
  final Map<String, List<Album>> genreResults;

  FakeDiscogsService(this.results, {this.genreResults = const {}});

  @override
  Future<List<Album>> fetchAlbums({String? query, String? genre}) async {
    calls.add((query: query, genre: genre));
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
  testWidgets('busca manual e gêneros preservam semântica OU', (tester) async {
    final service = FakeDiscogsService([
      album('Artist - Rock album', 1, 'Rock'),
      album('Artist - Jazz album', 2, 'Jazz'),
      album('Artist - Pop album', 3, 'Pop'),
    ]);
    await openStore(tester, service);
    await tester.enterText(find.byType(TextField), 'Artist');
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls, hasLength(1));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(service.calls.last.query, 'Artist');
    await applyGenres(tester);
    expect(displayedTitles(tester), [
      'Artist - Rock album',
      'Artist - Jazz album',
    ]);
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
    expect(displayedTitles(tester), ['Artist - Album']);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField), 'Artist');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();
    expect(displayedTitles(tester), ['Artist - Album', 'Artist - Album']);
    expect(find.text('Finalizar Compra (2 itens)'), findsOneWidget);
  });
}
