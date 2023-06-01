import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spendmate/common/constsnt.dart';
import 'package:http/http.dart' as http;
import 'package:spendmate/common/token.dart';

class TransactionScreen extends StatefulWidget {
  final String transactionId;

  TransactionScreen({required this.transactionId});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  Map<String, dynamic> transactionData = {};
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
      fetchData();
    });
  }

  Future<void> fetchData() async {
    if (authToken == null) {
      logger.i('Token not available');
      return;
    }
    final url = Uri.parse(
        'https://spenmate-backend.vercel.app/api/transaction/${widget.transactionId}');

    final response = await http.get(
      url,
      headers: {
        'Token': authToken!,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        transactionData = responseData['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        transactionData = {
          'title': 'Error occurred while fetching data',
          'completed': false,
        };
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction ID: ${transactionData['_id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Transaction Type: ${transactionData['transactionType']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Category: ${transactionData['category']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Description: ${transactionData['description']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Amount: ${transactionData['amount']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Date: ${transactionData['date']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Created At: ${transactionData['createdAt']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Updated At: ${transactionData['updatedAt']}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
