import '../model/album_model.dart';
import 'album_results.dart';

/// Split only a spaced separator so hyphenated names remain intact.
({String artist, String title}) splitAlbumTitle(String text) {
  final normalized = normalizeAlbumText(text);
  final separator = RegExp(r'\s+[-–—]\s+').firstMatch(normalized);
  if (separator == null) {
    return (artist: '', title: normalized);
  }
  return (
    artist: normalized.substring(0, separator.start),
    title: normalized.substring(separator.end),
  );
}

bool hasExactArtist(String query, Iterable<Album> albums) {
  final normalized = normalizeAlbumText(query);
  return normalized.isNotEmpty &&
      albums.any((album) => splitAlbumTitle(album.title).artist == normalized);
}

/// Exact artist intent is decided from the structured artist response only.
/// Otherwise require every query token, preserving source order on ties.
List<Album> rankAlbumSearch(
  String query, {
  required List<Album> artistResults,
  required List<Album> titleResults,
  List<Album> complementaryResults = const [],
}) {
  final normalized = normalizeAlbumText(query);
  if (normalized.isEmpty) return [];
  if (hasExactArtist(normalized, artistResults)) {
    return artistResults
        .where((album) => splitAlbumTitle(album.title).artist == normalized)
        .toList();
  }

  final candidates = [
    ...titleResults,
    ...artistResults,
    ...complementaryResults,
  ];
  final scored = <({Album album, int score, int index})>[];
  for (var index = 0; index < candidates.length; index++) {
    final score = _relevance(normalized, candidates[index]);
    if (score > 0) {
      scored.add((album: candidates[index], score: score, index: index));
    }
  }
  scored.sort((a, b) {
    final comparison = b.score.compareTo(a.score);
    return comparison != 0 ? comparison : a.index.compareTo(b.index);
  });
  return scored.map((entry) => entry.album).toList();
}

Set<String> _tokens(String text) =>
    text.split(' ').where((token) => token.isNotEmpty).toSet();

int _relevance(String query, Album album) {
  final parts = splitAlbumTitle(album.title);
  final explicit = splitAlbumTitle(query);
  final artistTokens = _tokens(parts.artist);
  final titleTokens = _tokens(parts.title);
  if (explicit.artist.isNotEmpty) {
    if (!artistTokens.containsAll(_tokens(explicit.artist)) ||
        !titleTokens.containsAll(_tokens(explicit.title)) ||
        explicit.title.isEmpty) {
      return 0;
    }
    if (parts.artist == explicit.artist && parts.title == explicit.title) {
      return 400;
    }
    return parts.title == explicit.title ? 300 : 200;
  }

  if (parts.title == query) return 350;
  final queryTokens = _tokens(query);
  if (!{...artistTokens, ...titleTokens}.containsAll(queryTokens)) return 0;

  // A partial artist match alone is not a combined artist/album query.
  final spansBoth =
      queryTokens.any(
        (token) => artistTokens.contains(token) && !titleTokens.contains(token),
      ) &&
      queryTokens.any(
        (token) => titleTokens.contains(token) && !artistTokens.contains(token),
      );
  if (spansBoth) {
    final allTokens = {...artistTokens, ...titleTokens};
    if (queryTokens.containsAll(allTokens)) return 400;
    if (queryTokens.containsAll(titleTokens)) return 300;
    return 200;
  }
  return titleTokens.containsAll(queryTokens) ? 100 : 0;
}
