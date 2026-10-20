import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/utils/album_search.dart';

Album album(String title) => Album(title: title, image: '', genres: []);

void main() {
  final bad = album('Michael Jackson - Bad');
  final puppets = album('Metallica - Master Of Puppets');
  final distractions = [
    album('Michael Gregory Jackson - Cowboys'),
    album('Michael Jackson - Dangerous'),
    album('Other Artist - Bad'),
    album('Michael Jackson - Bad Remixes'),
    album('Metallica - Metallica'),
    album('Various - A Tribute To Metallica'),
  ];

  for (final query in [
    'Michael Jackson - Bad',
    'Bad Michael Jackson',
    'Michael Jackson Bad',
    'michael bad',
    '  MICHAEL   JACKSON - BAD  ',
  ]) {
    test('$query prioriza Michael Jackson - Bad', () {
      final results = rankAlbumSearch(
        query,
        artistResults: [],
        titleResults: distractions,
        complementaryResults: [bad],
      );
      expect(results.first, same(bad));
      expect(results, isNot(contains(distractions[1])));
      expect(results, isNot(contains(distractions[2])));
    });
  }

  for (final query in [
    'Master of Puppets Metallica',
    'Metallica Master of Puppets',
  ]) {
    test('$query prioriza Metallica - Master Of Puppets', () {
      expect(
        rankAlbumSearch(
          query,
          artistResults: distractions,
          titleResults: [],
          complementaryResults: [puppets],
        ),
        [puppets],
      );
    });
  }

  test('artista exato Metallica prioriza discografia e exclui tributos', () {
    final results = rankAlbumSearch(
      '  METALLICA ',
      artistResults: [distractions.last, puppets, distractions[4]],
      titleResults: [album('Other - Metallica')],
    );
    expect(results, [puppets, distractions[4]]);
  });

  test('artista exato exclui Michael Gregory Jackson', () {
    expect(
      rankAlbumSearch(
        '  michael   jackson ',
        artistResults: [distractions.first, bad],
        titleResults: [],
      ),
      [bad],
    );
  });

  test('não aceita artista parcial isolado como busca combinada', () {
    expect(
      rankAlbumSearch(
        'Michael Jackson',
        artistResults: [distractions.first],
        titleResults: [],
        complementaryResults: [distractions.first],
      ),
      isEmpty,
    );
  });

  test('Master of Puppets prioriza título exato antes de parcial', () {
    final partial = album(
      'Dream Theater - Official Bootleg: Master Of Puppets',
    );
    final sameTitle = album('Alaska Pipeline - Master Of Puppets');
    expect(
      rankAlbumSearch(
        'Master of Puppets',
        artistResults: [],
        titleResults: [partial, puppets, sameTitle],
      ),
      [puppets, sameTitle, partial],
    );
  });

  test('álbum exato com artista parcial precede álbum parcial', () {
    final partial = album('Michael Jackson - Bad Remixes');
    expect(
      rankAlbumSearch(
        'michael bad',
        artistResults: [],
        titleResults: [partial, bad],
      ),
      [bad, partial],
    );
  });

  test('exige todos os termos da consulta e preserva pontuação e acentos', () {
    expect(
      rankAlbumSearch(
        'Michael Jackson Unknown',
        artistResults: [bad],
        titleResults: [bad],
      ),
      isEmpty,
    );
    expect(
      rankAlbumSearch(
        'Album',
        artistResults: [],
        titleResults: [album('Artist - Álbum'), album('Artist - Album!')],
      ),
      isEmpty,
    );
  });

  test('título sem artista pode corresponder e hífen interno é preservado', () {
    final titleOnly = album('Bad');
    expect(
      rankAlbumSearch('Bad', artistResults: [], titleResults: [titleOnly]),
      [titleOnly],
    );
    expect(splitAlbumTitle('Jay-Z - Album'), (artist: 'jay-z', title: 'album'));
    expect(splitAlbumTitle('Artist - Album - Deluxe'), (
      artist: 'artist',
      title: 'album - deluxe',
    ));
  });
}
