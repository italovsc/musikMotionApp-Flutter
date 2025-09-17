import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
        });
      }
    }
  }

  String _fieldLabel(String fieldKey) {
    switch (fieldKey) {
      case 'name': return 'nome';
      case 'lastName': return 'sobrenome';
      case 'email': return 'email';
      case 'address': return 'endereço';
      case 'city': return 'cidade';
      case 'state': return 'estado';
      default: return fieldKey;
    }
  }

  Future<void> _editField(String fieldName, String currentValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${_fieldLabel(fieldName)}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Novo ${_fieldLabel(fieldName)}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({fieldName: newValue});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_fieldLabel(fieldName)} atualizado com sucesso!'), duration: Duration(milliseconds: 800)),
                );
                _fetchUserData();
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Perfil'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.person, size: 100, color: Colors.white),
            SizedBox(height: 20),
            _buildInfoRow('Nome', userData!['name']),
            _buildInfoRow('Sobrenome', userData!['lastName']),
            _buildInfoRow('Email', userData!['email']),
            _buildInfoRow('Endereço', userData!['address']),
            _buildInfoRow('Cidade', userData!['city']),
            _buildInfoRow('Estado', userData!['state']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: Colors.grey),
            onPressed: () => _editField(_fieldKey(label), value),
          ),
        ],
      ),
    );
  }

  String _fieldKey(String label) {
    switch (label) {
      case 'Nome': return 'name';
      case 'Sobrenome': return 'lastName';
      case 'Endereço': return 'address';
      case 'Cidade': return 'city';
      case 'Estado': return 'state';
      default: return '';
    }
  }
}
