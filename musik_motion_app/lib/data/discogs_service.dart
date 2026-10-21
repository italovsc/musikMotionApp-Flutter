import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/album_details.dart';
import '../model/album_model.dart';
import '../utils/album_results.dart';
import '../utils/album_search.dart';

class DiscogsService {
  static const String _token = 'ZEfAUyffMjZfxDXICvdanBfAAHXJXjEAPjiBrSPd';
  static const String _baseUrl = 'api.discogs.com';

  final http.Client? _client;

  DiscogsService({http.Client? client}) : _client = client;

  Future<AlbumDetails> fetchAlbumDetails(int masterId) async {
    if (masterId <= 0) {
      throw ArgumentError.value(masterId, 'masterId', 'Deve ser positivo');
    }
    final data = await _fetchDetailsJson('/masters/$masterId');
    final details = AlbumDetails.fromJson(data);
    final releaseId = details.mainReleaseId;
    if (releaseId == null) return details;

    AlbumRating? rating;
    try {
      rating = AlbumRating.fromJson(
        await _fetchDetailsJson('/releases/$releaseId/rating'),
      );
    } on Exception {
      // Rating is optional: a failure must not discard the master details.
      return details;
    }
    return AlbumDetails.fromJson(data, rating: rating);
  }

  Future<Map<String, dynamic>> _fetchDetailsJson(String path) async {
    final get = _client?.get ?? http.get;
    final response = await get(
      Uri.https(_baseUrl, path),
      headers: {
        'Authorization': 'Discogs token=$_token',
        'User-Agent': 'MusikMotion/1.0',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar detalhes do álbum: ${response.statusCode}',
      );
    }
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Resposta de detalhes inválida');
    }
    return data;
  }

  Future<List<Album>> fetchAlbums({String? query, String? genre}) async {
    final text = query?.trim() ?? '';
    if (text.isEmpty) {
      return _search(genre: genre);
    }

    final artists = await _search(field: 'artist', text: text, genre: genre);
    final titles = await _search(
      field: 'release_title',
      text: text,
      genre: genre,
    );
    final ranked = rankAlbumSearch(
      text,
      artistResults: artists,
      titleResults: titles,
    );
    if (hasExactArtist(text, artists)) return ranked;

    // Multiword input may combine artist and album in either order.
    // Broad search is only a complementary source; it gets the same ranking.
    final mayBeCombined = normalizeAlbumText(text).contains(' ');
    if (!mayBeCombined && ranked.isNotEmpty) return ranked;
    final complementary = await _search(field: 'q', text: text, genre: genre);
    return rankAlbumSearch(
      text,
      artistResults: artists,
      titleResults: titles,
      complementaryResults: complementary,
    );
  }

  // Only the first page is currently requested. Keep page selection centralized
  // for future pagination; these results are not the complete catalog.
  Future<List<Album>> _search({
    String? field,
    String? text,
    String? genre,
    int page = 1,
  }) async {
    final params = <String, String>{
      'type': 'master',
      'format': 'album',
      'per_page': '100',
      'page': '$page',
    };
    if (field != null && text != null) params[field] = text;
    if (genre != null && genre.isNotEmpty) {
      params['genre'] = genre;
    }

    final uri = Uri.https(_baseUrl, '/database/search', params);

    final get = _client?.get ?? http.get;
    final response = await get(
      uri,
      headers: {
        'Authorization': 'Discogs token=$_token',
        'User-Agent': 'MusikMotion/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar álbuns: ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));

    final List results = data['results'] ?? [];

    return results
        .where((json) {
          final formats = List<String>.from(json['format'] ?? []);
          return !formats.any(
            (format) => normalizeAlbumText(format) == 'unofficial release',
          );
        })
        .map((json) => Album.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
