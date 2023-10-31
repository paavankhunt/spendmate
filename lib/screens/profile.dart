import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spendmate/common/constsnt.dart';
import 'package:spendmate/common/token.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? authToken;

  @override
  void initState() {
    super.initState();
    getToken().then((String? token) {
      // Use the token value here
      if (token != null) {
        setState(() {
          authToken = token;
        });
      } else {
        logger.i('Token not found');
      }
      fetchUserData();
    });
  }

  Future<void> fetchUserData() async {
    final url = Uri.parse('https://spenmate-backend.vercel.app/api/user');

    final response = await http.get(
      url,
      headers: {
        'Token': authToken!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        userData = responseData['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to fetch user data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData != null
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.purple),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 120, // Set the height of the container
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Transform.translate(
                                offset: Offset(0, 60),
                                child: CircleAvatar(
                                  radius: 60,
                                  child: Text(
                                    userData!['name'][0]
                                        .toString()
                                        .toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 50, color: Colors.white),
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          margin: const EdgeInsets.only(top: 80),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${userData!['name'][0].toString().toUpperCase()}${userData!['name'].toString().substring(1)}',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${userData!['email']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ]))
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    'No user data available.',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
    );
  }
}
