import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spendmate/common/constsnt.dart';
import 'package:spendmate/common/token.dart';
import 'package:spendmate/screens/analytics.dart';
import 'package:spendmate/screens/login.dart';
import 'package:spendmate/screens/newtransaction.dart';
import 'package:spendmate/screens/profile.dart';
import 'package:spendmate/screens/transaction.dart';
import 'package:spendmate/screens/updatetransaction.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> data = [];
  String? authToken;
  bool isLoading = true;
  bool isDeleting = false;
  late TabController _tabController;
  TransactionType selectedTransactionType = TransactionType.All;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Initialize the TabController

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void updateTransactionType(TransactionType type) {
    setState(() {
      selectedTransactionType = type;
    });
  }

  List<Map<String, dynamic>> getFilteredData() {
    if (selectedTransactionType == TransactionType.All) {
      return data;
    } else {
      return data
          .where((item) =>
              item['transactionType'] ==
              selectedTransactionType.toString().split('.').last)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Logout'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await removeToken();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                updateTransactionType(TransactionType.All);
                break;
              case 1:
                updateTransactionType(TransactionType.Expense);
                break;
              case 2:
                updateTransactionType(TransactionType.Income);
                break;
            }
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (getFilteredData().isEmpty)
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        buildTransactionListWidget(TransactionType.All),
                        buildTransactionListWidget(TransactionType.Expense),
                        buildTransactionListWidget(TransactionType.Income),
                      ],
                    ),
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
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnalyticsPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewTransactionForm(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTransactionListWidget(TransactionType type) {
    final filteredData = getFilteredData().where((item) {
      if (type == TransactionType.All) {
        return true;
      } else if (type == TransactionType.Expense) {
        return item['transactionType'] == 'Expense';
      } else {
        return item['transactionType'] == 'Income';
      }
    }).toList();

    return ListView(
      children: filteredData.map((item) {
        bool isExpense = item['transactionType'] == 'Expense';
        Color borderColor = isExpense ? Colors.red : Colors.green;

        return GestureDetector(
          // onTap: () {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => TransactionScreen(
          //         transactionId: item['_id'] ?? '',
          //       ),
          //     ),
          //   );
          // },
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width:
                              150, // Specify the desired width for the category
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              int maxLines = 1;
                              if (constraints.maxHeight > 40) {
                                maxLines = 2;
                              }
                              return Text(
                                item['category'],
                                maxLines: maxLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
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
                                    builder: (context) => UpdateTransactionForm(
                                      transactionId: item['_id'] ?? '',
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
                                final transactionId = item['_id'] as String?;
                                if (transactionId != null) {
                                  confirmDeleteTransaction(transactionId);
                                } else {
                                  logger.i('Transaction ID is null');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width:
                              120, // Specify the desired width for the description
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              int maxLines = 2;
                              if (constraints.maxHeight > 32) {
                                maxLines =
                                    1; // Remove the line limit when expanded
                              }
                              return Text(
                                item['description'],
                                maxLines: maxLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14),
                              );
                            },
                          ),
                        ),
                        Text(
                          item['date'].toString().split('T').first,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${item['amount'].toString()} ₹',
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
        );
      }).toList(),
    );
  }
}

enum TransactionType {
  All,
  Expense,
  Income,
}
