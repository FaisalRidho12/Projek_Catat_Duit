import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import 'edit_transaction_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<FinanceTransaction> transactions = [];
  List<FinanceTransaction> filteredTransactions = [];
  List<Category> categories = [];

  DateTime? selectedDate;
  String? selectedType;
  int? selectedCategoryId;

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadAll();
  }

  void loadCategories() async {
    final allCategories = await ApiService.getCategories();
    setState(() {
      categories = allCategories;
    });
  }

  Future<void> loadAll() async {
    final data = await ApiService.getAllTransactions();
    setState(() {
      transactions = data;
      filteredTransactions = data;
    });
  }

  void filterTransactions() {
    setState(() {
      filteredTransactions = transactions.where((t) {
        final transactionDate =
            DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parse(t.date);

        bool matchesDate = selectedDate == null
            ? true
            : transactionDate.year == selectedDate!.year &&
                transactionDate.month == selectedDate!.month &&
                transactionDate.day == selectedDate!.day;

        bool matchesCategory =
            selectedCategoryId == null || t.categoryId == selectedCategoryId;
        bool matchesType = selectedType == null || t.type == selectedType;

        return matchesDate && matchesCategory && matchesType;
      }).toList();
    });
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        filterTransactions();
      });
    }
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
                  await loadAll(); // Ambil ulang data setelah selesai edit
                  filterTransactions(); // filter biar tampilan diperbarui
                }); // Reload data setelah edit
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
        content: const Text(
            'Apakah Anda yakin ingin menghapus transaksi ini? Data saldo juga akan berubah.'),
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
              await loadAll();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = categories
        .where((c) => selectedType == null || c.type == selectedType)
        .map((c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text(c.name),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    selectedDate == null
                        ? 'Semua Tanggal'
                        : DateFormat('dd MMM yyyy').format(selectedDate!),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: selectedType ?? 'Semua',
                  items: const [
                    DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                    DropdownMenuItem(
                        value: 'expense', child: Text('Pengeluaran')),
                    DropdownMenuItem(value: 'Semua', child: Text('Semua Tipe')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedType = val == 'Semua' ? null : val;
                      selectedCategoryId = null;
                      filterTransactions();
                    });
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedCategoryId,
                    isExpanded: true,
                    items: categoryItems,
                    onChanged: (val) {
                      setState(() {
                        selectedCategoryId = val;
                        filterTransactions();
                      });
                    },
                    hint: const Text('Pilih Kategori'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text('Tidak ada transaksi.'))
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final t = filteredTransactions[index];
                      final rawDate =
                          DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
                              .parse(t.date);
                      final formattedDate =
                          DateFormat('dd MMM yyyy • HH:mm').format(rawDate);
                      final amountText =
                          '${t.type == 'income' ? '+' : '-'} ${currencyFormat.format(t.amount)}';

                      return ListTile(
                        title: Text(t.description),
                        subtitle: Text('$formattedDate • ${t.categoryName}'),
                        trailing: Text(
                          amountText,
                          style: TextStyle(
                            color:
                                t.type == 'income' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _showTransactionOptions(t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
