import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/discogs_service.dart';
import '../model/album_model.dart';
import '../utils/album_presentation.dart';
import '../utils/album_results.dart';
import 'cart_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;
  int _searchVersion = 0;

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
    _searchDebounce?.cancel();
    _searchVersion++;
    searchController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    // Invalidate immediately, including the time spent waiting for the timer.
    _searchVersion++;
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 450), _fetchAlbums);
  }

  void _clearSearch() {
    searchController.clear();
    _fetchAlbums();
  }

  Future<void> _fetchAlbums() async {
    _searchDebounce?.cancel();
    if (!mounted) return;
    final version = ++_searchVersion;
    setState(() {
      isLoading = true;
      albums = [];
    });

    final discogsService = context.read<DiscogsService>();

    final searchText = searchController.text.trim();

    final selectedGenres =
        genres.entries
            .where((genre) => genre.value)
            .map((genre) => genre.key)
            .toList();

    List<Album> fetched = [];

    try {
      if (searchText.isEmpty && selectedGenres.isEmpty) {
        fetched = await discogsService.fetchAlbums();
      } else if (searchText.isNotEmpty && selectedGenres.isEmpty) {
        fetched = await discogsService.fetchAlbums(query: searchText);
      } else if (searchText.isNotEmpty && selectedGenres.isNotEmpty) {
        final results = await discogsService.fetchAlbums(query: searchText);

        fetched =
            results.where((album) {
              return selectedGenres.any(
                (genre) => album.genres.contains(genre),
              );
            }).toList();
      } else {
        final genreResults = <List<Album>>[];
        for (final genre in selectedGenres) {
          final results = await discogsService.fetchAlbums(genre: genre);

          genreResults.add(results);
        }
        fetched = interleaveAlbumResults(genreResults);
      }

      if (!mounted || version != _searchVersion) {
        return;
      }

      setState(() {
        albums = deduplicateAlbums(fetched);
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) {
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
      if (mounted && version == _searchVersion) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showGenreFilterDialog() {
    final pendingGenres = Map<String, bool>.from(genres);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filtrar por Gêneros'),
              content: SingleChildScrollView(
                child: Column(
                  children:
                      pendingGenres.keys.map((genre) {
                        return CheckboxListTile(
                          title: Text(genre),
                          value: pendingGenres[genre],
                          onChanged: (value) {
                            setStateDialog(() {
                              pendingGenres[genre] = value ?? false;
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
                    genres.addAll(pendingGenres);
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
            icon:
                cart.isEmpty
                    ? const Icon(Icons.shopping_cart)
                    : Badge(
                      label: Text('${cart.length}'),
                      child: const Icon(Icons.shopping_cart),
                    ),
            onPressed: () async {
              _dismissKeyboard();

              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen(cart: cart)),
              );
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _dismissKeyboard();
              _showGenreFilterDialog();
            },
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
                hintText: 'Buscar por artista ou álbum...',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Limpar busca',
                        onPressed: _clearSearch,
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        _dismissKeyboard();
                        _fetchAlbums();
                      },
                    ),
                  ],
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                _dismissKeyboard();
                _fetchAlbums();
              },
              onTapOutside: (_) {
                _dismissKeyboard();
              },
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : albums.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Nenhum resultado encontrado',
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tente outro artista, álbum ou remova os filtros.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        final presentation = albumPresentation(album.title);
                        final textTheme = Theme.of(context).textTheme;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            // Allow a 72px leading image within ListTile's constraints.
                            visualDensity: const VisualDensity(vertical: 4),
                            titleAlignment: ListTileTitleAlignment.center,
                            isThreeLine: presentation.artist != null,
                            leading: SizedBox(
                              width: 72,
                              height: 72,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child:
                                    album.image.isNotEmpty
                                        ? Image.network(
                                          album.image,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  const Icon(Icons.album),
                                        )
                                        : const Icon(Icons.album),
                              ),
                            ),
                            title: Text(
                              presentation.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (presentation.artist != null)
                                    Text(
                                      presentation.artist!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodyMedium,
                                    ),
                                  Text(
                                    album.genres.isNotEmpty
                                        ? album.genres.join(', ')
                                        : 'Sem gênero',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_shopping_cart),
                              onPressed: () {
                                _dismissKeyboard();

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
