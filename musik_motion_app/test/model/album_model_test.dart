import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/model/album_model.dart';

void main() {
  group('Album.fromJson', () {
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
