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
  bool _obscurePassword = true;

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
    if (context.read<AuthBloc>().state is AuthLoading) return;
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

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

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
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.album, size: 44),
                        const SizedBox(height: 12),
                        Text(
                          'Musik Motion',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Criar conta',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preencha seus dados para começar a explorar o catálogo.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Dados pessoais',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: nameController,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('Nome', Icons.person_outline),
                          validator: (value) {
                            return _requiredValidator(value, 'o nome');
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: lastNameController,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            'Sobrenome',
                            Icons.badge_outlined,
                          ),
                          validator: (value) {
                            return _requiredValidator(value, 'o sobrenome');
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: emailController,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            'Email',
                            Icons.email_outlined,
                          ),
                          validator: _emailValidator,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            'Senha',
                            Icons.lock_outline,
                            suffix: IconButton(
                              tooltip:
                                  _obscurePassword
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            ),
                          ),
                          validator: _passwordValidator,
                        ),

                        const SizedBox(height: 24),
                        Text(
                          'Endereço',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: addressController,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            'Endereço',
                            Icons.home_outlined,
                          ),
                          validator: (value) {
                            return _requiredValidator(value, 'o endereço');
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: cityController,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            'Cidade',
                            Icons.location_city_outlined,
                          ),
                          validator: (value) {
                            return _requiredValidator(value, 'a cidade');
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: stateController,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.done,
                          decoration: _decoration('Estado', Icons.map_outlined),
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
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                                      : const Text('Criar conta'),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Já possui uma conta?'),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Entrar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
