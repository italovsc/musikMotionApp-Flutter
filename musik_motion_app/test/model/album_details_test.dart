import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/model/album_details.dart';

void main() {
  test('Master completo preserva artistas, ano, gêneros, estilos e faixas', () {
    final details = AlbumDetails.fromJson({
      'id': 6495,
      'title': 'Master Of Puppets',
      'artists': [
        {'name': 'Metallica', 'join': '&'},
        {'name': 'Guest', 'join': ''},
      ],
      'year': 1986,
      'genres': ['Rock'],
      'styles': ['Thrash', 'Speed Metal'],
      'main_release': 1549636,
      'tracklist': [
        {
          'position': 'A1',
          'title': 'Battery',
          'duration': '5:10',
          'type_': 'track',
        },
        {'position': '', 'title': 'Side B', 'duration': '', 'type_': 'heading'},
      ],
    });
    expect(details.masterId, 6495);
    expect(details.title, 'Master Of Puppets');
    expect(details.artists.map((artist) => artist.name), [
      'Metallica',
      'Guest',
    ]);
    expect(details.artists.first.join, '&');
    expect(details.artists.last.join, isNull);
    expect(details.year, 1986);
    expect(details.genres, ['Rock']);
    expect(details.styles, ['Thrash', 'Speed Metal']);
    expect(details.mainReleaseId, 1549636);
    expect(details.tracklist.first.position, 'A1');
    expect(details.tracklist.first.title, 'Battery');
    expect(details.tracklist.first.duration, '5:10');
    expect(details.tracklist.first.type, 'track');
    expect(details.tracklist.last.type, 'heading');
    expect(details.tracklist.last.duration, isNull);
    expect(details.rating, isNull);
  });

  test('prefere imagem primary válida', () {
    final details = AlbumDetails.fromJson({
      'id': 1,
      'images': [
        {'type': 'secondary', 'uri': 'https://example.com/back.jpg'},
        {'type': 'primary', 'uri': ''},
        {'type': 'primary', 'uri': 'https://example.com/front.jpg'},
      ],
    });
    expect(details.imageUrl, 'https://example.com/front.jpg');
  });

  test('sem primary válida usa primeira imagem com URI preenchida', () {
    final details = AlbumDetails.fromJson({
      'id': 1,
      'images': [
        {'type': 'primary'},
        {'uri': '  '},
        {'uri': 'https://example.com/first.jpg'},
        {'uri': 'https://example.com/second.jpg'},
      ],
    });
    expect(details.imageUrl, 'https://example.com/first.jpg');
  });

  test('campos opcionais ausentes recebem defaults', () {
    final details = AlbumDetails.fromJson({'id': 1});
    expect(details.title, 'Sem título');
    expect(details.artists, isEmpty);
    expect(details.year, isNull);
    expect(details.genres, isEmpty);
    expect(details.styles, isEmpty);
    expect(details.imageUrl, isNull);
    expect(details.tracklist, isEmpty);
    expect(details.mainReleaseId, isNull);
  });

  test('ano e main_release não positivos são ausentes', () {
    for (final value in [0, -1, null]) {
      final details = AlbumDetails.fromJson({
        'id': 1,
        'year': value,
        'main_release': value,
      });
      expect(details.year, isNull);
      expect(details.mainReleaseId, isNull);
    }
  });

  test('duração vazia, em branco ou ausente vira null', () {
    for (final value in ['', '  ', null]) {
      expect(AlbumTrack.fromJson({'duration': value}).duration, isNull);
    }
  });

  test('tolera dados opcionais de tipos inesperados', () {
    final details = AlbumDetails.fromJson({
      'id': 1,
      'artists': [null, 42],
      'genres': ['Rock', null],
      'styles': false,
      'images': [
        {'uri': 42},
      ],
      'tracklist': 'invalid',
    });
    expect(details.artists, isEmpty);
    expect(details.genres, ['Rock']);
    expect(details.styles, isEmpty);
    expect(details.imageUrl, isNull);
    expect(details.tracklist, isEmpty);
  });

  test('Master exige identidade positiva válida', () {
    for (final id in [null, 0, -1, '1']) {
      expect(() => AlbumDetails.fromJson({'id': id}), throwsFormatException);
    }
  });

  test('avaliação converte números para double sem mudar escala', () {
    for (final average in [4, 4.64, 0]) {
      final rating = AlbumRating.fromJson({
        'release_id': 1549636,
        'rating': {'average': average, 'count': 889},
      });
      expect(rating.releaseId, 1549636);
      expect(rating.average, isA<double>());
      expect(rating.average, average);
      expect(rating.count, 889);
    }
  });

  test('avaliação ausente não é confundida com zero votos', () {
    expect(
      () => AlbumRating.fromJson({'release_id': 1}),
      throwsFormatException,
    );
  });
}
