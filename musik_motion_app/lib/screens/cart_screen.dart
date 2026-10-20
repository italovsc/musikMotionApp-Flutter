import 'package:flutter/material.dart';

import '../model/album_model.dart';

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
      body: widget.cart.isEmpty
          ? const Center(child: Text('O carrinho está vazio!'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];

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
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          leading: item.image.isNotEmpty
                              ? Image.network(
                                  item.image,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.album),
                          title: Text(item.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              _removeItem(index);
                            },
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
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/success');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF371717),
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
