import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/discogs_service.dart';
import '../model/album_details.dart';
import '../model/album_model.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final Album album;
  final ValueChanged<Album> onAddToCart;

  const AlbumDetailsScreen({
    super.key,
    required this.album,
    required this.onAddToCart,
  });

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  Future<AlbumDetails>? _details;

  @override
  void initState() {
    super.initState();
    final id = widget.album.masterId;
    if (id != null && id > 0) _details = _fetchDetails(id);
  }

  Future<AlbumDetails> _fetchDetails(int id) async =>
      context.read<DiscogsService>().fetchAlbumDetails(id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do álbum')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              widget.onAddToCart(widget.album);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.album.title} adicionado ao carrinho!',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Adicionar ao carrinho',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child:
            _details == null
                ? _content(null)
                : FutureBuilder<AlbumDetails>(
                  future: _details,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Não foi possível carregar os detalhes',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed:
                                    () => setState(() {
                                      _details = _fetchDetails(
                                        widget.album.masterId!,
                                      );
                                    }),
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return _content(snapshot.data!);
                  },
                ),
      ),
    );
  }

  Widget _content(AlbumDetails? details) {
    final textTheme = Theme.of(context).textTheme;
    final image = details?.imageUrl ?? widget.album.image;
    final artists =
        details?.artists
            .where((artist) => artist.name.trim().isNotEmpty)
            .toList() ??
        <AlbumArtist>[];
    final artistText = StringBuffer();
    for (var i = 0; i < artists.length; i++) {
      artistText.write(artists[i].name);
      if (i < artists.length - 1) {
        final join = artists[i].join;
        artistText.write(
          join != null && join.trim().isNotEmpty ? ' $join ' : ', ',
        );
      }
    }
    final genres = details?.genres ?? widget.album.genres;
    final rating = details?.rating;
    final average = rating?.average
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '')
        .replaceAll('.', ',');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      image.trim().isEmpty
                          ? const Icon(Icons.album, size: 96)
                          : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.album, size: 96),
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            details?.title ?? widget.album.title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (artists.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              artistText.toString(),
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          if (details == null) ...[
            const Text(
              'Detalhes adicionais não estão disponíveis.',
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              details.year == null
                  ? 'Ano não informado'
                  : 'Ano: ${details.year}',
            ),
          ],
          if (genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Gêneros: ${genres.join(', ')}'),
            ),
          if (details != null) ...[
            if (details.styles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Estilos: ${details.styles.join(', ')}'),
              ),
            const SizedBox(height: 20),
            Text(
              rating == null
                  ? 'Avaliação indisponível'
                  : rating.count == 0
                  ? 'Sem avaliações'
                  : '★ $average · ${rating.count} avaliações',
              style: textTheme.titleMedium,
            ),
            if (rating != null && rating.count > 0)
              Text(
                'Avaliação da edição principal na Discogs',
                style: textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            Text('Faixas', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            if (details.tracklist.isEmpty) const Text('Faixas não informadas'),
            for (final track in details.tracklist)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child:
                    track.type != 'track'
                        ? Text(track.title, style: textTheme.titleSmall)
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (track.position.isNotEmpty)
                              SizedBox(width: 40, child: Text(track.position)),
                            Expanded(child: Text(track.title)),
                            if (track.duration != null) ...[
                              const SizedBox(width: 12),
                              Flexible(child: Text(track.duration!)),
                            ],
                          ],
                        ),
              ),
          ],
        ],
      ),
    );
  }
}
