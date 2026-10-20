import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../data/auth_service.dart';
import '../data/firebase_firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    final user = authService.currentUser;

    if (user == null) {
      return;
    }

    final data = await firestoreService.getUserData(user.uid);

    if (data != null && mounted) {
      setState(() {
        userData = data;
      });
    }
  }

  String _fieldLabel(String fieldKey) {
    switch (fieldKey) {
      case 'name':
        return 'nome';
      case 'lastName':
        return 'sobrenome';
      case 'address':
        return 'endereço';
      case 'city':
        return 'cidade';
      case 'state':
        return 'estado';
      default:
        return fieldKey;
    }
  }

  Future<void> _editField(String fieldName, String currentValue) async {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    final user = authService.currentUser;

    if (user == null) return;

    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Editar ${_fieldLabel(fieldName)}'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Novo ${_fieldLabel(fieldName)}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newValue = controller.text.trim();

                  if (newValue.isEmpty) {
                    return;
                  }

                  await firestoreService.updateUserField(
                    uid: user.uid,
                    field: fieldName,
                    value: newValue,
                  );

                  if (!mounted || !dialogContext.mounted) {
                    return;
                  }

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_fieldLabel(fieldName)} atualizado com sucesso!',
                      ),
                      duration: const Duration(milliseconds: 800),
                    ),
                  );

                  await _fetchUserData();
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            _buildInfoRow('Nome', userData!['name']),
            _buildInfoRow('Sobrenome', userData!['lastName']),
            _buildInfoRow('Email', userData!['email'], editable: false),
            _buildInfoRow('Endereço', userData!['address']),
            _buildInfoRow('Cidade', userData!['city']),
            _buildInfoRow('Estado', userData!['state']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {bool editable = true}) {
    final displayValue = value?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(displayValue)),
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
              onPressed: () {
                _editField(_fieldKey(label), displayValue);
              },
            ),
        ],
      ),
    );
  }

  String _fieldKey(String label) {
    switch (label) {
      case 'Nome':
        return 'name';
      case 'Sobrenome':
        return 'lastName';
      case 'Endereço':
        return 'address';
      case 'Cidade':
        return 'city';
      case 'Estado':
        return 'state';
      default:
        return '';
    }
  }
}
