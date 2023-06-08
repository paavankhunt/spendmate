import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:spendmate/screens/splash_screen.dart';

import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/signup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Practice',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      routes: {
        '/home': (context) => MyHomePage(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
      },
    );
  }
}
