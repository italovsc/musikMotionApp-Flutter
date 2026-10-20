import 'package:flutter/material.dart';

import '../model/album_model.dart';
import '../utils/album_presentation.dart';

class CartScreen extends StatefulWidget {
  final List<Album> cart;

  const CartScreen({required this.cart, super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _removeItem(int index) {
    final item = widget.cart[index];

    setState(() {
      widget.cart.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} removido do carrinho'),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seu Carrinho')),
      body:
          widget.cart.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Seu carrinho está vazio',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Adicione discos da loja para começar.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.cart.length,
                      itemBuilder: (context, index) {
                        final item = widget.cart[index];
                        final presentation = albumPresentation(item.title);
                        final textTheme = Theme.of(context).textTheme;

                        return Dismissible(
                          key: ValueKey('${item.title}-$index'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            _removeItem(index);
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              visualDensity: const VisualDensity(vertical: 4),
                              titleAlignment: ListTileTitleAlignment.center,
                              isThreeLine:
                                  presentation.artist != null &&
                                  item.genres.isNotEmpty,
                              leading: SizedBox(
                                width: 72,
                                height: 72,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child:
                                      item.image.isNotEmpty
                                          ? Image.network(
                                            item.image,
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
                              subtitle:
                                  presentation.artist != null ||
                                          item.genres.isNotEmpty
                                      ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (presentation.artist != null)
                                              Text(
                                                presentation.artist!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.bodyMedium,
                                              ),
                                            if (item.genres.isNotEmpty)
                                              Text(
                                                item.genres.join(', '),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.bodySmall,
                                              ),
                                          ],
                                        ),
                                      )
                                      : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  _removeItem(index);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/success');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Finalizar Compra (${widget.cart.length} itens)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
