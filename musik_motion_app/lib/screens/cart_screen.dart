import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, String>> cart;

  const CartScreen({required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seu Carrinho'),
      ),
      body: widget.cart.isEmpty
          ? Center(child: Text('O carrinho está vazio!'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final item = widget.cart[index];
                return Dismissible(
                  key: ValueKey(item['title']! + index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      widget.cart.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item['title']} removido do carrinho'),
                        duration: Duration(milliseconds: 1000),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: item['image']!.isNotEmpty
                        ? Image.network(item['image']!, width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.album),
                    title: Text(item['title']!),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          widget.cart.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item['title']} removido do carrinho'),
                            duration: Duration(milliseconds: 1000),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/success');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF371717),
                ),
                child: Text(
                  'Finalizar Compra (${widget.cart.length} itens)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
