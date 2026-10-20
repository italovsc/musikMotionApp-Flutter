import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth_bloc.dart';
import 'bloc/auth_state.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/store_screen.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[HomeScreen(), StoreScreen(), const ProfileScreen()];

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is AuthUnauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Theme.of(context).primaryColor,
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Casa'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Loja'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Usuário'),
          ],
        ),
      ),
    );
  }
}
