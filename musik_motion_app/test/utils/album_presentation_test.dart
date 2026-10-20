import 'package:flutter_test/flutter_test.dart';
import 'package:trabalhomobile/utils/album_presentation.dart';

void main() {
  test('separa artista e álbum mantendo capitalização', () {
    expect(albumPresentation('Metallica - Master Of Puppets'), (
      artist: 'Metallica',
      title: 'Master Of Puppets',
    ));
  });

  test('sem separador mantém título completo e omite artista', () {
    expect(albumPresentation('Master Of Puppets'), (
      artist: null,
      title: 'Master Of Puppets',
    ));
  });

  test('usa somente o primeiro separador e mantém hífens posteriores', () {
    expect(albumPresentation('Artist - Album - Live 2026'), (
      artist: 'Artist',
      title: 'Album - Live 2026',
    ));
    expect(albumPresentation('Jay-Z - Album'), (
      artist: 'Jay-Z',
      title: 'Album',
    ));
  });
}
