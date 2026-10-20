import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $fieldName';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o email';
    }

    final email = value.trim();

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Informe um email válido';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe a senha';
    }

    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }

    return null;
  }

  void _register(BuildContext context) {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        email: emailController.text.trim(),
        password: passwordController.text,
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
      appBar: AppBar(title: const Text('Cadastro')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) {
            return;
          }

          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
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
                duration: const Duration(milliseconds: 1500),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text('Musik Motion', style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) {
                    return _requiredValidator(value, 'o nome');
                  },
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Sobrenome'),
                  validator: (value) {
                    return _requiredValidator(value, 'o sobrenome');
                  },
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _emailValidator,
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  validator: _passwordValidator,
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                  validator: (value) {
                    return _requiredValidator(value, 'o endereço');
                  },
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: cityController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                  validator: (value) {
                    return _requiredValidator(value, 'a cidade');
                  },
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: stateController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  validator: (value) {
                    return _requiredValidator(value, 'o estado');
                  },
                  onFieldSubmitted: (_) {
                    _register(context);
                  },
                ),

                const SizedBox(height: 20),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed:
                          state is AuthLoading
                              ? null
                              : () => _register(context),
                      child:
                          state is AuthLoading
                              ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Cadastrar'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
