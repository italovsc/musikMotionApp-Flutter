import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/data/discogs_service.dart';
import 'package:trabalhomobile/model/album_details.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/screens/album_details_screen.dart';

class DetailsService extends DiscogsService {
  int calls = 0;
  Future<AlbumDetails> Function() fetch;
  DetailsService(this.fetch);
  @override
  Future<AlbumDetails> fetchAlbumDetails(int masterId) {
    calls++;
    return fetch();
  }
}

AlbumDetails details({
  AlbumRating? rating,
  String? image,
  bool empty = false,
  String title = 'Master Of Puppets',
}) => AlbumDetails(
  masterId: 6495,
  title: title,
  artists: [
    AlbumArtist(name: 'Metallica', join: '&'),
    AlbumArtist(name: ''),
    AlbumArtist(name: 'Guest'),
  ],
  year: empty ? null : 1986,
  genres: empty ? [] : ['Rock'],
  styles: empty ? [] : ['Thrash'],
  imageUrl: image,
  rating: rating,
  tracklist:
      empty
          ? []
          : [
            AlbumTrack(position: '', title: 'Side A', type: 'heading'),
            AlbumTrack(
              position: 'A1',
              title: 'Battery',
              duration: '5:10',
              type: 'track',
            ),
            AlbumTrack(
              position: 'A2',
              title: 'Unknown duration',
              type: 'track',
            ),
          ],
);

Future<void> openDetails(
  WidgetTester tester,
  DetailsService service, {
  Album? album,
  ValueChanged<Album>? onAdd,
}) async {
  await tester.pumpWidget(
    RepositoryProvider<DiscogsService>.value(
      value: service,
      child: MaterialApp(
        home: AlbumDetailsScreen(
          album:
              album ??
              Album(
                title: 'Original title',
                image: '',
                genres: [],
                masterId: 6495,
              ),
          onAddToCart: onAdd ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('loading e rebuild não repetem consulta; dispose é seguro', (
    tester,
  ) async {
    final pending = Completer<AlbumDetails>();
    final service = DetailsService(() => pending.future);
    await openDetails(tester, service);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    tester.element(find.byType(AlbumDetailsScreen)).markNeedsBuild();
    await tester.pump();
    expect(service.calls, 1);
    await tester.pumpWidget(const SizedBox());
    pending.complete(details());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra dados, múltiplos artistas, rating, heading e faixas', (
    tester,
  ) async {
    await openDetails(
      tester,
      DetailsService(
        () async => details(
          rating: AlbumRating(releaseId: 2, average: 4.64, count: 889),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final text in [
      'Master Of Puppets',
      'Metallica & Guest',
      'Ano: 1986',
      'Gêneros: Rock',
      'Estilos: Thrash',
      '★ 4,64 · 889 avaliações',
      'Avaliação da edição principal na Discogs',
      'Faixas',
      'Side A',
      'A1',
      'Battery',
      '5:10',
      'Unknown duration',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('0:00'), findsNothing);
    expect(find.byIcon(Icons.album), findsOneWidget);
  });

  for (final votes in [null, 0]) {
    testWidgets('rating $votes e dados opcionais vazios', (tester) async {
      await openDetails(
        tester,
        DetailsService(
          () async => details(
            empty: true,
            rating:
                votes == null
                    ? null
                    : AlbumRating(releaseId: 2, average: 0, count: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(votes == null ? 'Avaliação indisponível' : 'Sem avaliações'),
        findsOneWidget,
      );
      expect(find.text('Ano não informado'), findsOneWidget);
      expect(find.text('Faixas não informadas'), findsOneWidget);
      expect(find.textContaining('Gêneros:'), findsNothing);
      expect(find.textContaining('Estilos:'), findsNothing);
    });
  }

  for (final primary in [true, false]) {
    testWidgets(
      'imagem ${primary ? 'de detalhes' : 'fallback do Album'} e erro',
      (tester) async {
        await openDetails(
          tester,
          DetailsService(
            () async => details(
              image: primary ? 'https://example.com/primary.jpg' : null,
            ),
          ),
          album: Album(
            title: 'Album',
            image: 'https://example.com/fallback.jpg',
            genres: [],
            masterId: 1,
          ),
        );
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(find.byType(Image));
        expect(
          (image.image as NetworkImage).url,
          'https://example.com/${primary ? 'primary' : 'fallback'}.jpg',
        );
        expect(image.fit, BoxFit.cover);
        expect(find.byIcon(Icons.album), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('erro e retry na mesma tela', (tester) async {
    final service = DetailsService(() async => throw Exception('offline'));
    await openDetails(tester, service);
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar os detalhes'), findsOneWidget);
    service.fetch = () async => details();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('Master Of Puppets'), findsOneWidget);
  });

  for (final id in [null, 0]) {
    testWidgets('masterId $id não consulta e permite adições do mesmo objeto', (
      tester,
    ) async {
      final original = Album(
        title: 'Basic album',
        image: '',
        genres: ['Rock'],
        masterId: id,
      );
      final added = <Album>[];
      final service = DetailsService(() async => details());
      await openDetails(tester, service, album: original, onAdd: added.add);
      await tester.pumpAndSettle();
      expect(service.calls, 0);
      expect(find.text('Basic album'), findsOneWidget);
      expect(
        find.text('Detalhes adicionais não estão disponíveis.'),
        findsOneWidget,
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Adicionar ao carrinho'));
        await tester.pump();
      }
      expect(added, hasLength(2));
      expect(added.every((item) => identical(item, original)), isTrue);
      expect(find.text('Basic album adicionado ao carrinho!'), findsOneWidget);
    });
  }

  testWidgets('tela pequena, fonte ampliada e textos longos sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final data = details(title: List.filled(40, 'Álbum').join(' '));
    data.tracklist.add(
      AlbumTrack(
        position: 'B1',
        title: List.filled(40, 'Faixa').join(' '),
        type: 'track',
      ),
    );
    await openDetails(tester, DetailsService(() async => data));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Adicionar ao carrinho').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
