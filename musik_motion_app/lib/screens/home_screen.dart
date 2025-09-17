import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Musik', style: TextStyle(fontSize: 48, fontStyle: FontStyle.italic)),
            Text('Motion', style: TextStyle(fontSize: 48, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
