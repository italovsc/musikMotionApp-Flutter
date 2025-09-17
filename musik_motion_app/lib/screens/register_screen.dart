import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  void _register(BuildContext context) {
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            // opcional: loading overlay
          }
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cadastro realizado com sucesso!'),
                duration: Duration(milliseconds: 800),
              ),
            );
            Navigator.pushReplacementNamed(context, '/navigation');
          }
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: Duration(milliseconds: 800),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text('Musik Motion', style: TextStyle(fontSize: 36))),
              SizedBox(height: 20),
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nome')),
              SizedBox(height: 10),
              TextField(controller: lastNameController, decoration: InputDecoration(labelText: 'Sobrenome')),
              SizedBox(height: 10),
              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 10),
              TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Senha')),
              SizedBox(height: 10),
              TextField(controller: addressController, decoration: InputDecoration(labelText: 'Endereço')),
              SizedBox(height: 10),
              TextField(controller: cityController, decoration: InputDecoration(labelText: 'Cidade')),
              SizedBox(height: 10),
              TextField(controller: stateController, decoration: InputDecoration(labelText: 'Estado')),
              SizedBox(height: 20),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is AuthLoading ? null : () => _register(context),
                    child: state is AuthLoading
                        ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text('Cadastrar'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
