import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/model/album_model.dart';

void main() {
  group('Album.fromJson', () {
    test('usa id positivo do master antes de master_id', () {
      final album = Album.fromJson({
        'type': 'master',
        'id': 6495,
        'master_id': 99,
      });
      expect(album.masterId, 6495);
    });

    test('usa master_id positivo quando disponível', () {
      expect(
        Album.fromJson({
          'type': 'release',
          'id': 10,
          'master_id': 6495,
        }).masterId,
        6495,
      );
      expect(Album.fromJson({'master_id': 6495}).masterId, 6495);
    });

    test('não usa IDs ausentes, zero, negativos ou id de release', () {
      for (final json in <Map<String, dynamic>>[
        {},
        {'master_id': 0},
        {'master_id': -1},
        {'type': 'master', 'id': 0},
        {'type': 'release', 'id': 10},
      ]) {
        expect(Album.fromJson(json).masterId, isNull);
      }
    });

    test('cria Album com todos os dados recebidos', () {
      final json = {
        'title': 'Metallica - Master of Puppets',
        'cover_image': 'https://example.com/master.jpg',
        'genre': ['Rock', 'Metal'],
      };

      final album = Album.fromJson(json);

      expect(album.title, 'Metallica - Master of Puppets');
      expect(album.image, 'https://example.com/master.jpg');
      expect(album.genres, ['Rock', 'Metal']);
    });

    test('usa thumb quando cover_image não está disponível', () {
      final json = {
        'title': 'Thriller',
        'thumb': 'https://example.com/thriller.jpg',
        'genre': ['Pop'],
      };

      final album = Album.fromJson(json);

      expect(album.image, 'https://example.com/thriller.jpg');
    });

    test('usa valores padrão quando dados opcionais estão ausentes', () {
      final json = <String, dynamic>{};

      final album = Album.fromJson(json);

      expect(album.title, 'Sem título');
      expect(album.image, '');
      expect(album.genres, isEmpty);
    });
  });
}
