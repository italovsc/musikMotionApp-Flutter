import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/model/album_model.dart';
import 'package:trabalhomobile/utils/album_results.dart';

Album album(String title, {String image = ''}) =>
    Album(title: title, image: image, genres: []);

void main() {
  group('deduplicateAlbums', () {
    test('deduplica pelo master ID mesmo com títulos diferentes', () {
      final first = Album(title: 'First', image: '', genres: [], masterId: 10);
      final second = Album(title: 'Other', image: '', genres: [], masterId: 10);
      expect(deduplicateAlbums([first, second]), [first]);
    });

    test('preserva masters distintos com o mesmo título', () {
      final first = Album(title: 'Same', image: '', genres: [], masterId: 10);
      final second = Album(title: 'Same', image: '', genres: [], masterId: 20);
      expect(deduplicateAlbums([first, second]), [first, second]);
    });

    test('usa título como fallback para IDs nulos ou inválidos', () {
      final first = album(' Artist - Album ');
      final zero = Album(
        title: 'artist - album',
        image: '',
        genres: [],
        masterId: 0,
      );
      final negative = Album(
        title: 'ARTIST - ALBUM',
        image: '',
        genres: [],
        masterId: -1,
      );
      expect(deduplicateAlbums([first, zero, negative]), [first]);
    });

    test('remove títulos repetidos dentro da mesma lista', () {
      final first = album('Artist - Album');
      final other = album('Artist - Other');

      expect(deduplicateAlbums([first, other, album('Artist - Album')]), [
        first,
        other,
      ]);
    });

    test('normaliza maiúsculas e espaços do título completo', () {
      final first = album('  ARTIST   -  Album  ');

      expect(deduplicateAlbums([first, album('artist - album')]), [first]);
      expect(first.title, '  ARTIST   -  Album  ');
    });

    test('preserva o primeiro objeto e não modifica a lista original', () {
      final first = album('Artist - Album', image: 'first.jpg');
      final second = album('Artist - Album', image: 'second.jpg');
      final source = [first, second];

      final result = deduplicateAlbums(source);

      expect(result.single, same(first));
      expect(result.single.image, 'first.jpg');
      expect(source, [first, second]);
    });

    test('preserva diferenças de pontuação, acentos e artista', () {
      final source = [
        album('Artist - Álbum'),
        album('Artist - Album'),
        album('Artist: Álbum'),
        album('Other Artist - Álbum'),
      ];

      expect(deduplicateAlbums(source), source);
    });

    test('aceita lista vazia', () {
      expect(deduplicateAlbums([]), isEmpty);
    });
  });

  group('interleaveAlbumResults', () {
    test('intercala duas listas mantendo a ordem interna', () {
      final rock = [album('R0'), album('R1')];
      final jazz = [album('J0'), album('J1')];

      expect(interleaveAlbumResults([rock, jazz]), [
        rock[0],
        jazz[0],
        rock[1],
        jazz[1],
      ]);
    });

    test('continua com as listas restantes de tamanhos diferentes', () {
      final rock = [album('R0')];
      final jazz = [album('J0'), album('J1'), album('J2')];
      final pop = [album('P0'), album('P1')];

      expect(interleaveAlbumResults([rock, jazz, pop]), [
        rock[0],
        jazz[0],
        pop[0],
        jazz[1],
        pop[1],
        jazz[2],
      ]);
      expect(rock, hasLength(1));
      expect(jazz, hasLength(3));
      expect(pop, hasLength(2));
    });

    test('aceita listas vazias e uma única lista', () {
      final rock = [album('R0'), album('R1')];

      expect(interleaveAlbumResults([]), isEmpty);
      expect(interleaveAlbumResults([[], []]), isEmpty);
      expect(interleaveAlbumResults([rock]), rock);
      expect(interleaveAlbumResults([[], rock, []]), rock);
    });

    test('deduplica entre gêneros depois de intercalar', () {
      final rock = [album('R0'), album('Shared', image: 'rock.jpg')];
      final jazz = [album(' SHARED ', image: 'jazz.jpg'), album('J1')];

      final result = deduplicateAlbums(interleaveAlbumResults([rock, jazz]));

      expect(result, [rock[0], jazz[0], jazz[1]]);
      expect(result[1], same(jazz[0]));
    });
  });
}
