import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trabalhomobile/data/discogs_service.dart';

Map<String, dynamic> result(String title, {List<String>? formats}) => {
  'type': 'master',
  'id': 10,
  'title': title,
  if (formats != null) 'format': formats,
};

http.Response response(List<Map<String, dynamic>> results) =>
    http.Response(jsonEncode({'results': results}), 200);

void main() {
  group('fetchAlbumDetails', () {
    for (final count in [889, 0]) {
      test('consulta Master e rating preservando $count votos', () async {
        final paths = <String>[];
        final client = MockClient((request) async {
          paths.add(request.url.path);
          expect(request.headers.containsKey('authorization'), isTrue);
          expect(request.headers['user-agent'], 'MusikMotion/1.0');
          expect(request.headers['accept'], 'application/json');
          expect(request.url.host, 'api.discogs.com');
          expect(request.url.scheme, 'https');
          return http.Response(
            jsonEncode(
              paths.length == 1
                  ? {
                    'id': 6495,
                    'title': 'Master Of Puppets',
                    'main_release': 1549636,
                  }
                  : {
                    'release_id': 1549636,
                    'rating': {
                      'average': count == 0 ? 0 : 4.64,
                      'count': count,
                    },
                  },
            ),
            200,
          );
        });
        addTearDown(client.close);
        final details = await DiscogsService(
          client: client,
        ).fetchAlbumDetails(6495);
        expect(paths, ['/masters/6495', '/releases/1549636/rating']);
        expect(details.title, 'Master Of Puppets');
        expect(details.masterId, 6495);
        expect(details.mainReleaseId, 1549636);
        expect(details.rating!.releaseId, 1549636);
        expect(details.rating!.count, count);
        expect(details.rating!.average, count == 0 ? 0.0 : 4.64);
        expect(details.rating!.average, isA<double>());
      });
    }

    for (final failure in ['http', 'network', 'json', 'shape']) {
      test('falha de rating ($failure) preserva detalhes', () async {
        final client = MockClient((request) async {
          if (request.url.path == '/masters/1') {
            return http.Response(
              '{"id":1,"title":"Bad","main_release":2}',
              200,
            );
          }
          switch (failure) {
            case 'network':
              throw http.ClientException('offline');
            case 'json':
              return http.Response('invalid json', 200);
            case 'shape':
              return http.Response('{}', 200);
            default:
              return http.Response('', 500);
          }
        });
        addTearDown(client.close);
        final details = await DiscogsService(
          client: client,
        ).fetchAlbumDetails(1);
        expect(details.title, 'Bad');
        expect(details.mainReleaseId, 2);
        expect(details.rating, isNull);
      });
    }

    for (final releaseId in [null, 0, -1]) {
      test('main_release $releaseId não faz segunda chamada', () async {
        var calls = 0;
        final client = MockClient((request) async {
          calls++;
          return http.Response(
            jsonEncode({
              'id': 1,
              if (releaseId != null) 'main_release': releaseId,
            }),
            200,
          );
        });
        addTearDown(client.close);
        final details = await DiscogsService(
          client: client,
        ).fetchAlbumDetails(1);
        expect(calls, 1);
        expect(details.rating, isNull);
      });
    }

    for (final status in [404, 429, 500]) {
      test('falha HTTP $status do Master propaga erro', () async {
        var calls = 0;
        final client = MockClient((_) async {
          calls++;
          return http.Response('', status);
        });
        addTearDown(client.close);
        await expectLater(
          DiscogsService(client: client).fetchAlbumDetails(1),
          throwsException,
        );
        expect(calls, 1);
      });
    }

    test('Master malformado propaga erro', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      addTearDown(client.close);
      await expectLater(
        DiscogsService(client: client).fetchAlbumDetails(1),
        throwsFormatException,
      );
    });

    test('masterId inválido não consulta rede', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      addTearDown(client.close);
      await expectLater(
        DiscogsService(client: client).fetchAlbumDetails(0),
        throwsArgumentError,
      );
      expect(calls, 0);
    });
  });

  test(
    'catálogo e gênero usam master, album e primeira página de 100',
    () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return response([result('Metallica - Bad')]);
      });
      addTearDown(client.close);
      final service = DiscogsService(client: client);
      await service.fetchAlbums();
      await service.fetchAlbums(genre: 'Rock');
      expect(requests.first.queryParameters, {
        'type': 'master',
        'format': 'album',
        'per_page': '100',
        'page': '1',
      });
      expect(requests.last.queryParameters['genre'], 'Rock');
    },
  );

  test(
    'faz duas consultas estruturadas e prioriza artista exato sem q',
    () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        final params = request.url.queryParameters;
        expect(params['type'], 'master');
        expect(params['format'], 'album');
        expect(params['per_page'], '100');
        expect(params['genre'], 'Rock');
        if (params.containsKey('artist')) {
          expect(params['artist'], 'Metallica');
          return response([
            result('Various - Metallica Tribute'),
            result('Metallica - Master Of Puppets'),
          ]);
        }
        expect(params['release_title'], 'Metallica');
        return response([result('Other - Metallica')]);
      });
      addTearDown(client.close);
      final albums = await DiscogsService(
        client: client,
      ).fetchAlbums(query: ' Metallica ', genre: 'Rock');
      expect(requests, hasLength(2));
      expect(albums.single.title, 'Metallica - Master Of Puppets');
    },
  );

  for (final query in [
    'Michael Jackson - Bad',
    'Bad Michael Jackson',
    'Michael Jackson Bad',
    'michael bad',
    'Master of Puppets Metallica',
    'Metallica Master of Puppets',
  ]) {
    test('fonte q complementar encontra e classifica $query', () async {
      final requests = <Uri>[];
      final target =
          query.contains('Metallica')
              ? 'Metallica - Master Of Puppets'
              : 'Michael Jackson - Bad';
      final client = MockClient((request) async {
        requests.add(request.url);
        final params = request.url.queryParameters;
        if (!params.containsKey('q')) return response([]);
        expect(params['q'], query);
        expect(params['type'], 'master');
        expect(params['format'], 'album');
        return response([
          result('Michael Jackson - Dangerous'),
          result('Various - Bad'),
          result(target),
        ]);
      });
      addTearDown(client.close);
      final albums = await DiscogsService(
        client: client,
      ).fetchAlbums(query: query);
      expect(requests, hasLength(3));
      expect(albums.single.title, target);
    });
  }

  test('título simples útil não exige consulta q', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return response(
        request.url.queryParameters.containsKey('release_title')
            ? [result('Michael Jackson - Bad')]
            : [],
      );
    });
    addTearDown(client.close);
    final albums = await DiscogsService(
      client: client,
    ).fetchAlbums(query: 'Bad');
    expect(albums.single.title, 'Michael Jackson - Bad');
    expect(requests, hasLength(2));
  });

  test(
    'fallback q é usado quando estruturadas não têm resultados úteis',
    () async {
      final client = MockClient(
        (request) async => response([
          result(
            request.url.queryParameters.containsKey('q')
                ? 'Artist - Target'
                : 'Irrelevant - Other',
          ),
        ]),
      );
      addTearDown(client.close);
      final albums = await DiscogsService(
        client: client,
      ).fetchAlbums(query: 'Target');
      expect(albums.single.title, 'Artist - Target');
    },
  );

  test(
    'remove somente Unofficial Release e aceita ausência de format',
    () async {
      final client = MockClient(
        (_) async => response([
          result(
            'Artist - Unofficial',
            formats: ['Album', 'Unofficial Release'],
          ),
          result('Artist - Official', formats: ['Album']),
          result('Artist - Compilation', formats: ['Album', 'Compilation']),
          result('Artist - Live', formats: ['Album', 'Live']),
          result('Artist - Remix', formats: ['Album', 'Remix']),
          result('Artist - Unknown'),
        ]),
      );
      addTearDown(client.close);
      final albums = await DiscogsService(client: client).fetchAlbums();
      expect(albums.map((album) => album.title), [
        'Artist - Official',
        'Artist - Compilation',
        'Artist - Live',
        'Artist - Remix',
        'Artist - Unknown',
      ]);
      expect(albums.first.masterId, 10);
    },
  );

  test('propaga falha HTTP', () async {
    final client = MockClient((_) async => http.Response('', 429));
    addTearDown(client.close);
    await expectLater(
      DiscogsService(client: client).fetchAlbums(),
      throwsException,
    );
  });

  test('aceita resposta sem results', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    addTearDown(client.close);
    expect(await DiscogsService(client: client).fetchAlbums(), isEmpty);
  });
}
