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

    var editedValue = currentValue;

    await showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Editar ${_fieldLabel(fieldName)}'),
            content: TextFormField(
              initialValue: currentValue,
              onChanged: (value) => editedValue = value,
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
                  final newValue = editedValue.trim();

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
  }

  Widget _logoutButton() => OutlinedButton.icon(
    onPressed: () {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    },
    icon: const Icon(Icons.logout),
    label: const Text('Sair da conta'),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fullName = [userData?['name'], userData?['lastName']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' ');
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child:
            userData == null
                ? Column(
                  children: [
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _logoutButton(),
                    ),
                  ],
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: CircleAvatar(
                              radius: 28,
                              child: Icon(Icons.person, size: 32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fullName,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData!['email']?.toString() ?? '',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          _buildSection('Dados pessoais', [
                            _buildInfoRow(
                              'Nome',
                              userData!['name'],
                              Icons.person_outline,
                            ),
                            _buildInfoRow(
                              'Sobrenome',
                              userData!['lastName'],
                              Icons.badge_outlined,
                            ),
                          ]),
                          const SizedBox(height: 12),
                          _buildSection('Endereço', [
                            _buildInfoRow(
                              'Endereço',
                              userData!['address'],
                              Icons.home_outlined,
                            ),
                            _buildInfoRow(
                              'Cidade',
                              userData!['city'],
                              Icons.location_city,
                            ),
                            _buildInfoRow(
                              'Estado',
                              userData!['state'],
                              Icons.map_outlined,
                            ),
                          ]),
                          const SizedBox(height: 12),
                          _logoutButton(),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> fields) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: fields),
        ),
      ),
    ],
  );

  Widget _buildInfoRow(String label, dynamic value, IconData icon) {
    final displayValue = value?.toString() ?? '';
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      minTileHeight: 56,
      minVerticalPadding: 4,
      leading: Icon(icon, size: 22),
      title: Text(label, style: textTheme.bodySmall),
      subtitle: Text(
        displayValue,
        style: textTheme.titleMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Editar ${_fieldLabel(_fieldKey(label))}',
        onPressed: () {
          _editField(_fieldKey(label), displayValue);
        },
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
