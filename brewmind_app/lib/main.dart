import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    //
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const BrewMindApp(),
    ),
  );
}

class BrewMindApp extends StatelessWidget {
  const BrewMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrewMind',
      debugShowCheckedModeBanner: false,

      // Dark café theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC8965A),
          secondary: Color(0xFF7EB8A4),
          surface: Color(0xFF1A1714),
          onPrimary: Color(0xFF1A1714),
          onSurface: Color(0xFFF0E8DC),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0D0B),
        fontFamily: 'DMSans',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1714),
          foregroundColor: Color(0xFFF0E8DC),
          elevation: 0,
        ),
      ),

      // Check authentication state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0D0B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('☕', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'BrewMind',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC8965A),
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Color(0xFFC8965A)),
          ],
        ),
      ),
    );
  }
}
