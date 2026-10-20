import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trabalhomobile/screens/login_screen.dart';
import 'package:trabalhomobile/screens/profile_screen.dart';

import 'data/auth_service.dart';
import 'data/firebase_firestore_service.dart';
import 'navigation_wrapper.dart';
import 'screens/purchase_success_screen.dart';
import 'screens/register_screen.dart';
import 'screens/store_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/firebase_options.dart';
import 'bloc/auth_bloc.dart';
import 'data/discogs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = AuthService();
  final firestoreService = FirestoreService();
  final discogsService = DiscogsService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<FirestoreService>.value(value: firestoreService),
        RepositoryProvider<DiscogsService>.value(value: discogsService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authService, firestoreService),
          ),
        ],
        child: MusikMotionApp(),
      ),
    ),
  );
}

class MusikMotionApp extends StatelessWidget {
  const MusikMotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musik Motion',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF2C0A0A), // Vinho escuro
        primaryColor: Color(0xFF4B1C1C), // Vermelho escuro
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF8C4A4A),
          secondary: Color(0xFFB46B6B),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
      ),
      initialRoute: authService.currentUser == null ? '/login' : '/navigation',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/navigation': (context) => NavigationWrapper(),
        '/store': (context) => StoreScreen(),
        '/success': (context) => PurchaseSuccessScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
