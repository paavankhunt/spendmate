import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spendmate/common/constsnt.dart';
import 'package:spendmate/common/token.dart';
import 'package:spendmate/common/validator.dart';
import 'package:spendmate/screens/home.dart';
import 'package:spendmate/screens/signup.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final GlobalKey<_LoginScreenState> loginPageKey =
      GlobalKey<_LoginScreenState>();

  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final String? token;
  late final String? authToken;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getToken().then((String? token) {
      if (token != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (Route<dynamic> route) => false,
        );
      } else {
        logger.i('Token not found');
      }
    });
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      setState(() {
        isLoading = true; // Start the login process
      });

      // Send a POST request to the login API endpoint
      final response = await http.post(
        Uri.parse('https://spenmate-backend.vercel.app/api/user/login'),
        body: {
          'email': email,
          'password': password,
        },
      );

      setState(() {
        isLoading = false; // Stop the login process
      });

      if (response.statusCode == 200) {
        // Login successful
        final responseData = json.decode(response.body);
        if (responseData.containsKey('data')) {
          final token = responseData['data'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage()),
            (Route<dynamic> route) => false,
          );
          // Navigate to the home screen or perform other actions
          logger.i(responseData);
        } else {
          // Handle the case where the 'data' field is not present in the response
          logger.e('Invalid response: No data field');
        }
      } else {
        // Login failed
        final responseData = json.decode(response.body);
        // Handle the error or display an error message to the user
        logger.e(responseData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
                          bool isValidEmail = validateEmail(value);
                          if (isValidEmail) {
                            return null;
                          } else {
                            return 'Email is not valid';
                          }
                        },
                        controller: _emailController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter Email',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          return null;
                        },
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter Password',
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          final String email = _emailController.text.trim();
                          final String password =
                              _passwordController.text.trim();
                          logger.i('$email $password');
                          _login(context);
                          // if (token != null) {
                          //   Navigator.pushAndRemoveUntil(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => const MyHomePage()),
                          //     (Route<dynamic> route) => false,
                          //   );
                          // } else {
                          //   showDialog<String>(
                          //     context: context,
                          //     builder: (BuildContext context) => AlertDialog(
                          //       title: const Text('Error'),
                          //       content: const Text('Data is not valid'),
                          //       actions: <Widget>[
                          //         TextButton(
                          //           onPressed: () => Navigator.pop(context, 'OK'),
                          //           child: const Text('OK'),
                          //         ),
                          //       ],
                          //     ),
                          //   );
                          // }
                        }
                      },
                      child: const Text('Login'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
