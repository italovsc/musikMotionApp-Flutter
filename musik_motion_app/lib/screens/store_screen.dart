import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/discogs_service.dart';
import '../model/album_model.dart';

import 'cart_screen.dart'; // Importa a tela do carrinho

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  TextEditingController searchController = TextEditingController();
  List<Album> albums = [];
  bool isLoading = false;
  List<Album> cart = []; // Estado do carrinho

  Map<String, bool> genres = {
    'Rock': false,
    'Pop': false,
    'Jazz': false,
    'Hip-Hop': false,
    'Electronic': false,
  };

  Future<void> _fetchAlbums() async {
    setState(() {
      isLoading = true;
      albums = [];
    });
    final discogsService = context.read<DiscogsService>();
    final searchText = searchController.text.trim();
    final selectedGenres = genres.entries
        .where((g) => g.value)
        .map((g) => g.key)
        .toList();
    List<Album> fetched = [];

    try {
      if (searchText.isEmpty && selectedGenres.isEmpty) {
        fetched = await discogsService.fetchAlbums();
      } else if (searchText.isNotEmpty && selectedGenres.isEmpty) {
        fetched = await discogsService.fetchAlbums(query: searchText);
      } else if (searchText.isNotEmpty && selectedGenres.isNotEmpty) {
        final results = await discogsService.fetchAlbums(query: searchText);

        fetched = results.where((album) {
          return selectedGenres.any((genre) => album.genres.contains(genre));
        }).toList();
      } else if (searchText.isEmpty && selectedGenres.isNotEmpty) {
        for (final genre in selectedGenres) {
          final results = await discogsService.fetchAlbums(genre: genre);

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
                      onChanged: (value) =>
                          setStateDialog(() => genres[genre] = value!),
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
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen(cart: cart)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showGenreFilterDialog,
          ),
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
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _fetchAlbums,
                ),
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

                      final title = album.title;
                      final image = album.image;
                      return ListTile(
                        leading: image.isNotEmpty
                            ? Image.network(image, width: 50, height: 50)
                            : Icon(Icons.album),
                        title: Text(title),
                        subtitle: album.genres.isNotEmpty
                            ? Text(album.genres.join(', '))
                            : const Text('Sem gênero'),
                        trailing: IconButton(
                          icon: Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            setState(() {
                              cart.add(album);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$title adicionado ao carrinho!'),
                                duration: Duration(milliseconds: 1000),
                              ),
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
