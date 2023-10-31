import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:spendmate/common/constsnt.dart';
import 'dart:convert';

import 'package:spendmate/common/token.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<MonthlyData> monthlyData = [];
  String? authToken;
  bool isLoading = false;

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
        print('Token not found');
      }
      fetchData();
    });
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

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

      // Clear the existing monthly data
      monthlyData.clear();

      // Group the transactions by month
      Map<String, List<Map<String, dynamic>>> groupedData = {};
      List<Map<String, dynamic>> transactions =
          List<Map<String, dynamic>>.from(responseData['data']);

      for (var transaction in transactions) {
        String month = transaction['date'].toString().substring(0, 7);
        if (groupedData.containsKey(month)) {
          groupedData[month]!.add(transaction);
        } else {
          groupedData[month] = [transaction];
        }
      }

      // Calculate the total expenses and incomes for each month
      groupedData.forEach((month, transactions) {
        double totalExpenses = 0;
        double totalIncomes = 0;

        for (var transaction in transactions) {
          double amount = transaction['amount'].toDouble();
          if (transaction['transactionType'] == 'Expense') {
            totalExpenses += amount;
          } else if (transaction['transactionType'] == 'Income') {
            totalIncomes += amount;
          }
        }

        monthlyData.add(MonthlyData(
            month: month, expenses: totalExpenses, incomes: totalIncomes));
      });

      monthlyData.sort((a, b) => a.month.compareTo(b.month));
    } else {
      monthlyData = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : monthlyData.isEmpty
                ? Text('No data available')
                : Column(
                    children: [
                      const Text(
                        'Monthly Expenses and Incomes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 400,
                        child: charts.BarChart(
                          _createSeriesData(),
                          animate: true,
                          vertical: true,
                          barGroupingType: charts.BarGroupingType.grouped,
                          barRendererDecorator:
                              charts.BarLabelDecorator<String>(),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  List<charts.Series<MonthlyData, String>> _createSeriesData() {
    final expenseSeries = charts.Series<MonthlyData, String>(
      id: 'Expenses',
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      domainFn: (MonthlyData data, _) => data.month,
      measureFn: (MonthlyData data, _) => data.expenses,
      data: monthlyData,
      displayName: 'Expenses',
    );

    final incomeSeries = charts.Series<MonthlyData, String>(
      id: 'Incomes',
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      domainFn: (MonthlyData data, _) => data.month,
      measureFn: (MonthlyData data, _) => data.incomes,
      data: monthlyData,
      displayName: 'Incomes',
    );

    return [expenseSeries, incomeSeries];
  }
}

class MonthlyData {
  final String month;
  final double expenses;
  final double incomes;

  MonthlyData({
    required this.month,
    required this.expenses,
    required this.incomes,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['date'].toString().substring(0, 7),
      expenses:
          json['transactionType'] == 'Expense' ? json['amount'].toDouble() : 0,
      incomes:
          json['transactionType'] == 'Income' ? json['amount'].toDouble() : 0,
    );
  }

  @override
  String toString() {
    return 'MonthlyData(month: $month, expenses: $expenses, incomes: $incomes)';
  }
}
