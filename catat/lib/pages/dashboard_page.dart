import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import untuk NumberFormat
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
    final data = await ApiService.getAllTransactions(); // Memanggil semua transaksi
    setState(() {
      transactions = data;
    });
  }

  // Menghitung total pemasukan
  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  // Menghitung total pengeluaran
  double get totalExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  // Menghitung saldo total
  double get totalBalance => totalIncome - totalExpense;

  // Filter transaksi berdasarkan tanggal hari ini
  List<FinanceTransaction> get transactionsToday {
    final today = DateTime.now();
    return transactions.where((t) {
      final transactionDate = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US').parse(t.date);
      return transactionDate.year == today.year &&
          transactionDate.month == today.month &&
          transactionDate.day == today.day;
    }).toList();
  }

  // Format uang
  String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return 'Rp${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cata Duit')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          // Menambahkan transaksi dan memuat ulang data setelah kembali
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
            _summaryCard('Saldo Saat Ini', totalBalance, const Color.fromARGB(255, 25, 149, 250)), // Menampilkan saldo total
            _summaryCard('Pemasukan Total', totalIncome, const Color.fromARGB(255, 26, 216, 32)), // Menampilkan total pemasukan
            _summaryCard('Pengeluaran Total', totalExpense, const Color.fromARGB(255, 239, 30, 15)), // Menampilkan total pengeluaran
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Transaksi Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)), // Menampilkan transaksi hari ini
            ),
            Expanded(
              child: ListView.builder(
                itemCount: transactionsToday.length,
                itemBuilder: (context, index) {
                  final t = transactionsToday[index];
                  return ListTile(
                    title: Text(t.description),
                    subtitle: Text(t.categoryName),
                    trailing: Text(
                      '${t.type == 'income' ? '+' : '-'} ${formatCurrency(t.amount)}',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: color.withOpacity(0.1),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          formatCurrency(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
