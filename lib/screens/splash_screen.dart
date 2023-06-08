import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendmate/screens/login.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add any necessary initialization code here
    _navigateToMainScreen();
  }

  Future<void> _navigateToMainScreen() async {
    // Simulate a delay before navigating to the main screen
    await Future.delayed(Duration(seconds: 2));

    // Navigate to the main screen and remove the splash screen from the stack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        child: Image.asset(
          'assets/splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
