import 'package:flutter/material.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Agradecemos por comprar com a Musik Motion®!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),
            Text('Esperamos que desfrute da música ao máximo!'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/navigation', (route) => false),
              child: Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}