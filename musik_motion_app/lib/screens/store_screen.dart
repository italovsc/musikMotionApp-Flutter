import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'cart_screen.dart'; // Importa a tela do carrinho

class StoreScreen extends StatefulWidget {
  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> albums = [];
  bool isLoading = false;
  List<Map<String, String>> cart = []; // Estado do carrinho

  Map<String, bool> genres = {
    'Rock': false,
    'Pop': false,
    'Jazz': false,
    'Hip-Hop': false,
    'Electronic': false,
  };

  final String _discogsToken = 'ZEfAUyffMjZfxDXICvdanBfAAHXJXjEAPjiBrSPd';

  Future<List<dynamic>> fetchAlbumsFromDiscogs({String? query, String? genre}) async {
    final params = <String, String>{
      'type': 'release',
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (genre != null && genre.isNotEmpty) params['genre'] = genre;

    final uri = Uri.https('api.discogs.com', '/database/search', params);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Discogs token=$_discogsToken',
        'User-Agent': 'MusikMotion/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load albums: ${response.statusCode}');
    }
  }

  Future<void> _fetchAlbums() async {
    setState(() {
      isLoading = true;
      albums = [];
    });

    final searchText = searchController.text.trim();
    final selectedGenres = genres.entries.where((g) => g.value).map((g) => g.key).toList();
    List<dynamic> fetched = [];

    try {
      if (searchText.isEmpty && selectedGenres.isEmpty) {
        fetched = await fetchAlbumsFromDiscogs();
      } else if (searchText.isNotEmpty && selectedGenres.isEmpty) {
        fetched = await fetchAlbumsFromDiscogs(query: searchText);
      } else if (searchText.isNotEmpty && selectedGenres.isNotEmpty) {
        final results = await fetchAlbumsFromDiscogs(query: searchText);
        fetched = results.where((album) {
          final albumGenres = List<String>.from(album['genre'] ?? []);
          return selectedGenres.any((g) => albumGenres.contains(g));
        }).toList();
      } else if (searchText.isEmpty && selectedGenres.isNotEmpty) {
        for (var genre in selectedGenres) {
          final results = await fetchAlbumsFromDiscogs(genre: genre);
          fetched.addAll(results);
        }
      }

      setState(() {
        albums = fetched;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showGenreFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Filtrar por Gêneros'),
              content: SingleChildScrollView(
                child: Column(
                  children: genres.keys.map((genre) {
                    return CheckboxListTile(
                      title: Text(genre),
                      value: genres[genre],
                      onChanged: (value) => setStateDialog(() => genres[genre] = value!),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchAlbums();
                  },
                  child: Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loja de Discos'),
        actions: [
          IconButton(icon: Icon(Icons.shopping_cart), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CartScreen(cart: cart),
              ),
            );
          }),
          IconButton(icon: Icon(Icons.filter_list), onPressed: _showGenreFilterDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por artista, álbum...',
                suffixIcon: IconButton(icon: Icon(Icons.search), onPressed: _fetchAlbums),
              ),
              onSubmitted: (_) => _fetchAlbums(),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : albums.isEmpty
                ? Center(child: Text('Nenhum resultado'))
                : ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final title = album['title'] ?? 'Sem título';
                final image = album['cover_image'] ?? '';
                return ListTile(
                  leading: image.isNotEmpty
                      ? Image.network(image, width: 50, height: 50)
                      : Icon(Icons.album),
                  title: Text(title),
                  subtitle: album['genre'] != null
                      ? Text((album['genre'] as List).join(', '))
                      : Text('Sem gênero'),
                  trailing: IconButton(
                    icon: Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      setState(() {
                        cart.add({'title': title, 'image': image});
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title adicionado ao carrinho!'),
                          duration: Duration(milliseconds: 1000),),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
