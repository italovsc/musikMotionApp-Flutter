import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/discogs_service.dart';
import '../model/album_model.dart';
import 'cart_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Album> albums = [];
  List<Album> cart = [];

  bool isLoading = false;

  final Map<String, bool> genres = {
    'Rock': false,
    'Pop': false,
    'Jazz': false,
    'Hip-Hop': false,
    'Electronic': false,
  };

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlbums() async {
    setState(() {
      isLoading = true;
      albums = [];
    });

    final discogsService = context.read<DiscogsService>();

    final searchText = searchController.text.trim();

    final selectedGenres = genres.entries
        .where((genre) => genre.value)
        .map((genre) => genre.key)
        .toList();

    List<Album> fetched = [];

    try {
      if (searchText.isEmpty && selectedGenres.isEmpty) {
        fetched = await discogsService.fetchAlbums();
      } else if (searchText.isNotEmpty && selectedGenres.isEmpty) {
        fetched = await discogsService.fetchAlbums(
          query: searchText,
        );
      } else if (searchText.isNotEmpty && selectedGenres.isNotEmpty) {
        final results = await discogsService.fetchAlbums(
          query: searchText,
        );

        fetched = results.where((album) {
          return selectedGenres.any(
            (genre) => album.genres.contains(genre),
          );
        }).toList();
      } else {
        for (final genre in selectedGenres) {
          final results = await discogsService.fetchAlbums(
            genre: genre,
          );

          fetched.addAll(results);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        albums = fetched;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os discos. Tente novamente.',
          ),
          duration: Duration(milliseconds: 1500),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showGenreFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filtrar por Gêneros'),
              content: SingleChildScrollView(
                child: Column(
                  children: genres.keys.map((genre) {
                    return CheckboxListTile(
                      title: Text(genre),
                      value: genres[genre],
                      onChanged: (value) {
                        setStateDialog(() {
                          genres[genre] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _fetchAlbums();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja de Discos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    cart: cart,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showGenreFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por artista, álbum...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _fetchAlbums,
                ),
              ),
              onSubmitted: (_) {
                _fetchAlbums();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : albums.isEmpty
                    ? const Center(
                        child: Text('Nenhum resultado'),
                      )
                    : ListView.builder(
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final album = albums[index];

                          return ListTile(
                            leading: album.image.isNotEmpty
                                ? Image.network(
                                    album.image,
                                    width: 50,
                                    height: 50,
                                  )
                                : const Icon(Icons.album),
                            title: Text(album.title),
                            subtitle: album.genres.isNotEmpty
                                ? Text(
                                    album.genres.join(', '),
                                  )
                                : const Text('Sem gênero'),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                              ),
                              onPressed: () {
                                setState(() {
                                  cart.add(album);
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${album.title} adicionado ao carrinho!',
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1000,
                                    ),
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