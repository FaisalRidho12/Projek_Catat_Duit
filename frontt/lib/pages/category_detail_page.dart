import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'edit_transaction_page.dart';
import '../services/api_service.dart';

class CategoryDetailPage extends StatefulWidget {
  final String categoryName;
  final List<FinanceTransaction> transactions;

  const CategoryDetailPage({
    super.key,
    required this.categoryName,
    required this.transactions,
  });

  @override
  _CategoryDetailPageState createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  List<FinanceTransaction> categoryTransactions = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    categoryTransactions = widget.transactions
        .where((t) => t.categoryName == widget.categoryName)
        .toList();
  }

  void _showTransactionOptions(FinanceTransaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditTransactionPage(transaction: transaction),
                  ),
                ).then((_) async {
                  await loadTransactions(); // Load ulang transaksi setelah edit
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Hapus'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(transaction.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Hapus'),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.deleteTransaction(id);
              await loadTransactions(); // Load ulang transaksi setelah hapus
            },
          ),
        ],
      ),
    );
  }

  Future<void> loadTransactions() async {
    final allTransactions = await ApiService
        .getAllTransactions(); // Sesuaikan dengan API atau sumber data
    setState(() {
      categoryTransactions = allTransactions
          .where((t) => t.categoryName == widget.categoryName)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail: ${widget.categoryName}')),
      body: ListView.builder(
        itemCount: categoryTransactions.length,
        itemBuilder: (context, index) {
          final t = categoryTransactions[index];

          // format tanggal dan waktu contohnya "Mon, 14 Apr 2025 14:46:00"
          final parsedDate =
              DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
                  .parse(t.date);
          final formattedDate =
              DateFormat('dd MMM yyyy • HH:mm').format(parsedDate);

          final amountText =
              '${t.type == 'income' ? '+' : '-'} ${currencyFormat.format(t.amount)}';

          return ListTile(
            title: Text(t.description),
            subtitle: Text(formattedDate),
            trailing: Text(
              amountText,
              style: TextStyle(
                color: t.type == 'income' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showTransactionOptions(t),
          );
        },
      ),
    );
  }
}
