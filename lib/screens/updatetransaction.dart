import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spendmate/common/constsnt.dart';
import 'package:spendmate/common/token.dart';
import 'package:spendmate/screens/home.dart';
import 'package:flutter/cupertino.dart';

class Transaction {
  String id;
  String transactionType;
  String category;
  String description;
  int amount;
  DateTime date;

  Transaction({
    required this.id,
    required this.transactionType,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });
}

class UpdateTransactionForm extends StatefulWidget {
  final String transactionId;

  const UpdateTransactionForm({required this.transactionId});

  @override
  _UpdateTransactionFormState createState() => _UpdateTransactionFormState();
}

class _UpdateTransactionFormState extends State<UpdateTransactionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _transactionTypeController =
      TextEditingController(text: 'Expense');
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  bool isLoading = true;
  String? authToken;

  @override
  void initState() {
    super.initState();
    getToken().then((String? token) {
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
      logger.i(responseData);
      final transaction = Transaction(
        id: responseData['data']['_id'],
        transactionType: responseData['data']['transactionType'],
        category: responseData['data']['category'],
        description: responseData['data']['description'],
        amount: responseData['data']['amount'],
        date: responseData['data']['date'] != null
            ? DateTime.parse(responseData['data']['date'])
            : DateTime.now(),
      );
      setState(() {
        isLoading = false;
      });
      setInitialValues(transaction);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  void dispose() {
    _transactionTypeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void setInitialValues(Transaction transaction) {
    _transactionTypeController.text = transaction.transactionType;
    _categoryController.text = transaction.category;
    _descriptionController.text = transaction.description;
    _amountController.text = transaction.amount.toString();
    _selectedDateTime = transaction.date;
  }

  Future<void> _submitTransaction(Map<String, dynamic> transactionData) async {
    final authToken = await getToken();
    if (authToken == null) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(
        'https://spenmate-backend.vercel.app/api/transaction/${widget.transactionId}');

    final response = await http.put(
      url,
      headers: {
        'Token': authToken,
      },
      body: transactionData,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      logger.i(responseData);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage()),
        (Route<dynamic> route) => false,
      );
      setState(() {
        isLoading = false;
      });
    } else {
      final errorData = json.decode(response.body);
      logger.i(errorData);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: Scaffold(
        appBar: AppBar(title: Text('Update Transaction')),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: DropdownButtonFormField<String>(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Transaction Type cannot be empty';
                      }
                      return null;
                    },
                    value: _transactionTypeController.text,
                    onChanged: (newValue) {
                      setState(() {
                        _transactionTypeController.text = newValue!;
                      });
                    },
                    items: <String>[
                      'Expense',
                      'Income',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Transaction Type',
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Category cannot be empty';
                      }
                      return null;
                    },
                    controller: _categoryController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Category',
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description cannot be empty';
                      }
                      return null;
                    },
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Amount cannot be empty';
                      }
                      // You can add additional validation for the amount if required
                      // For example, check if the value is a valid number
                      return null;
                    },
                    controller: _amountController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Amount',
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Date and Time',
                        hintText: 'Select Date and Time',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${_selectedDateTime.year}-${_selectedDateTime.month.toString().padLeft(2, '0')}-${_selectedDateTime.day.toString().padLeft(2, '0')} ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final String transactionType =
                          _transactionTypeController.text.trim();
                      final String category = _categoryController.text.trim();
                      final String description =
                          _descriptionController.text.trim();
                      final String amount = _amountController.text.trim();

                      final transactionData = {
                        'transactionType': transactionType,
                        'category': category,
                        'description': description,
                        'amount': amount,
                        'date': _selectedDateTime.toString(),
                      };

                      _submitTransaction(transactionData);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
