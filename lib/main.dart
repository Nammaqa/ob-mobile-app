import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:organize/screens/login_screen.dart';
import 'package:organize/screens/homepage_screen.dart';
import 'package:organize/screens/splash_screen.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Organize App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // Changed from LoginPage() to SplashScreen()
      routes: {
        '/splash': (context) => const SplashScreen(), // Optional: add splash route
        '/login': (context) => const LoginPage(),
        '/homepage': (context) => const HomepageScreen(),
      },
    );
  }
}