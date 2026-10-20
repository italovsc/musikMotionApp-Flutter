import '../model/album_model.dart';

String normalizeAlbumText(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Keeps the first master, falling back to full title only for missing IDs.
List<Album> deduplicateAlbums(Iterable<Album> albums) {
  final seenKeys = <String>{};

  return albums.where((album) {
    final id = album.masterId;
    final key =
        id != null && id > 0
            ? 'master:$id'
            : 'title:${normalizeAlbumText(album.title)}';
    return seenKeys.add(key);
  }).toList();
}

/// Takes one album per list in order, skipping lists that have ended.
List<Album> interleaveAlbumResults(List<List<Album>> results) {
  final albums = <Album>[];
  var index = 0;
  var hasMore = true;

  while (hasMore) {
    hasMore = false;
    for (final list in results) {
      if (index < list.length) {
        albums.add(list[index]);
        hasMore = true;
      }
    }
    index++;
  }

  return albums;
}
