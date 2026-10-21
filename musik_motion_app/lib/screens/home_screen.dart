import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onExploreCatalog});

  final VoidCallback onExploreCatalog;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: (constraints.maxHeight * .08).clamp(16, 80),
                          ),
                          const Icon(Icons.album, size: 48),
                          const SizedBox(height: 20),
                          Text(
                            'Musik Motion',
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Encontre discos por artista ou álbum e monte seu carrinho.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: onExploreCatalog,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Explorar catálogo'),
                          ),
                          SizedBox(
                            height: (constraints.maxHeight * .1).clamp(48, 96),
                          ),
                          const Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _HomeFeature(
                                    icon: Icons.search,
                                    title: 'Busque seus favoritos',
                                    description: 'Por artista ou álbum',
                                  ),
                                  SizedBox(height: 24),
                                  _HomeFeature(
                                    icon: Icons.filter_list,
                                    title: 'Explore por gênero',
                                    description: 'Descubra diferentes estilos',
                                  ),
                                  SizedBox(height: 24),
                                  _HomeFeature(
                                    icon: Icons.add_shopping_cart,
                                    title: 'Monte seu carrinho',
                                    description:
                                        'Adicione os discos que encontrar',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

class _HomeFeature extends StatelessWidget {
  const _HomeFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}
