import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spendmate/common/constsnt.dart';
import 'package:spendmate/common/token.dart';
import 'package:spendmate/screens/home.dart';

class NewTransactionForm extends StatefulWidget {
  const NewTransactionForm({Key? key}) : super(key: key);

  @override
  _NewTransactionFormState createState() => _NewTransactionFormState();
}

class _NewTransactionFormState extends State<NewTransactionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _transactionTypeController =
      TextEditingController(text: 'Expense');
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool isLoading = true;

  @override
  void dispose() {
    _transactionTypeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction(Map<String, dynamic> transactionData) async {
    final authToken = await getToken();
    if (authToken == null) {
      return;
    }
    setState(() {
      isLoading = true;
    });

    final url =
        Uri.parse('https://spenmate-backend.vercel.app/api/transaction/create');

    final response = await http.post(
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('New Transaction'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Date and Time',
                        hintText: 'Select Date and Time',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')} ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                          TextButton(
                            child: Text(
                              'Change Time',
                              style: TextStyle(fontSize: 16),
                            ),
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
                      // Form is valid, proceed with submitting the data
                      final String transactionType =
                          _transactionTypeController.text.trim();
                      final String category = _categoryController.text.trim();
                      final String description =
                          _descriptionController.text.trim();
                      final String amount = _amountController.text.trim();
                      final String date = _selectedDate.toIso8601String();

                      // Create the transaction data object
                      final transactionData = {
                        'transactionType': transactionType,
                        'category': category,
                        'description': description,
                        'amount': amount,
                        'date': date,
                      };
                      // Send the transaction data to the API or perform other actions
                      _submitTransaction(transactionData);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
