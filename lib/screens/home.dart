import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spendmate/common/constsnt.dart';
import 'package:spendmate/common/token.dart';
import 'package:spendmate/screens/login.dart';
import 'package:http/http.dart' as http;
import 'package:spendmate/screens/newtransaction.dart';
import 'package:spendmate/screens/transaction.dart';
import 'package:spendmate/screens/updatetransaction.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> data = [];
  String? authToken;
  bool isLoading = true;
  bool isDeleting = false;

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
      fetchData();
    });
  }

  Future<void> fetchData() async {
    if (authToken == null) {
      logger.i('Token not available');
      return;
    }
    final url =
        Uri.parse('https://spenmate-backend.vercel.app/api/transaction');

    final response = await http.get(
      url,
      headers: {
        'Token': authToken!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        data = List<Map<String, dynamic>>.from(responseData['data']);
        isLoading = false;
      });
    } else {
      setState(() {
        data = [
          {
            'title': 'Error occurred while fetching data',
            'completed': false,
          }
        ];
        isLoading = false;
      });
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (authToken == null) {
      logger.i('Token not available');
      return;
    }

    setState(() {
      isDeleting = true; // Start the deletion process
    });

    final url = Uri.parse(
        'https://spenmate-backend.vercel.app/api/transaction/$transactionId');

    final response = await http.delete(
      url,
      headers: {
        'Token': authToken!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      logger.i(responseData);
      fetchData();
      setState(() {
        isDeleting = false; // Stop the deletion process
      });
    } else {
      final responseData = json.decode(response.body);
      logger.i(responseData);
      setState(() {
        isDeleting = false; // Stop the deletion process
      });
    }
  }

  Future<void> confirmDeleteTransaction(String transactionId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content:
              const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                deleteTransaction(transactionId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await removeToken();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (data.isEmpty)
                  const Center(
                    child: Text(
                      'No transactions found.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  ListView(
                    children: data.map((item) {
                      bool isExpense = item['transactionType'] == 'Expense';
                      Color borderColor = isExpense ? Colors.red : Colors.green;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionScreen(
                                transactionId: item['_id'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          child: Card(
                            // shape: BeveledRectangleBorder(
                            //   borderRadius: BorderRadius.only(
                            //     topLeft: Radius.circular(8.0),
                            //     bottomLeft: Radius.circular(8.0),
                            //   ),
                            //   side: BorderSide(
                            //     color: borderColor,
                            //     width: 2.0,
                            //   ),
                            // ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: borderColor,
                                    width: 6.0,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['category'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              color: Colors.blue.shade400,
                                              icon: Icon(Icons.edit),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UpdateTransactionForm(
                                                      transactionId:
                                                          item['_id'] ?? '',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              color: Colors.red.shade400,
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                logger.i(item['_id']);
                                                final transactionId =
                                                    item['_id'] as String?;
                                                if (transactionId != null) {
                                                  confirmDeleteTransaction(
                                                      transactionId);
                                                } else {
                                                  logger.i(
                                                      'Transaction ID is null');
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(item['description']),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            'Rs. ${item['amount'].toString()}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (isDeleting)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewTransactionForm(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
