import 'dart:convert';
import 'package:http/http.dart' as http;
import '/model/album_model.dart';

class DiscogsService {
  static const String _token = 'ZEfAUyffMjZfxDXICvdanBfAAHXJXjEAPjiBrSPd';
  static const String _baseUrl = 'https://api.discogs.com';

  Future<List<Album>> searchAlbums(String query) async {
    final url = Uri.parse('$_baseUrl/database/search?q=$query&type=release&token=$_token');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      return results
          .map((json) => Album.fromJson(json))
          .where((album) => album.thumb.isNotEmpty)
          .toList();
    } else {
      throw Exception('Erro ao buscar álbuns do Discogs');
    }
  }
}
