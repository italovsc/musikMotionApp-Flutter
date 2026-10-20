import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/album_model.dart';

class DiscogsService {
  static const String _token = 'ZEfAUyffMjZfxDXICvdanBfAAHXJXjEAPjiBrSPd';
  static const String _baseUrl = 'api.discogs.com';

  Future<List<Album>> fetchAlbums({String? query, String? genre}) async {
    final params = <String, String>{'type': 'release'};

    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }

    if (genre != null && genre.isNotEmpty) {
      params['genre'] = genre;
    }

    final uri = Uri.https(_baseUrl, '/database/search', params);

    final response = await http.get(
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

    final data = json.decode(response.body);

    final List results = data['results'] ?? [];

    return results
        .map((json) => Album.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
