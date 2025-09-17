
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'screens/home_screen.dart';
import 'screens/store_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_state.dart';

class NavigationWrapper extends StatefulWidget {
  @override
  _NavigationWrapperState createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {

        final pages = <Widget>[
          HomeOnlyTitle(),
          StoreScreen(),
          // Se estiver autenticado, mostra o perfil, senão, a tela de login:
          authState is AuthAuthenticated
              ? ProfileScreen()
              : LoginScreen(),
        ];

        return Scaffold(
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: Theme.of(context).primaryColor,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Casa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store),
                label: 'Loja',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Usuário',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeOnlyTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Musik', style: TextStyle(fontSize: 48, fontStyle: FontStyle.italic)),
          Text('Motion', style: TextStyle(fontSize: 48, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
