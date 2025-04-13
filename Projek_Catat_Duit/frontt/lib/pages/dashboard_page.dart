import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import 'form_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<FinanceTransaction> transactions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await ApiService.getTodayTransactions();
    setState(() {
      transactions = data;
    });
  }

  double get todayIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get todayExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get todayBalance => todayIncome - todayExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cata Duit')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormPage()),
          );
          loadData();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryCard('Saldo Hari Ini', todayBalance, Colors.blue),
            _summaryCard('Pemasukan Hari Ini', todayIncome, Colors.green),
            _summaryCard('Pengeluaran Hari Ini', todayExpense, Colors.red),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Transaksi Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return ListTile(
                    title: Text(t.description),
                    subtitle: Text(t.categoryName),
                    trailing: Text(
                      '${t.type == 'income' ? '+' : '-'} Rp${t.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: t.type == 'income' ? Colors.green : Colors.red),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          'Rp${amount.toStringAsFixed(0)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
