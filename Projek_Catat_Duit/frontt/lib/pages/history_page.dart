import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

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
  String? selectedCategory;
  String? selectedType;
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadAll();
  }

  // Memuat kategori dari API
  void loadCategories() async {
    final allCategories = await ApiService.getCategories();
    setState(() {
      categories = allCategories;
    });
  }

  // Memuat semua transaksi dari API
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
        // Parse tanggal dari string
        final transactionDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parse(t.date);

        // Cocokkan tanggal
        bool matchesDate = selectedDate == null
            ? true
            : transactionDate.year == selectedDate!.year &&
                transactionDate.month == selectedDate!.month &&
                transactionDate.day == selectedDate!.day;

        // Cocokkan kategori ID dan jenis transaksi
        bool matchesCategory = selectedCategoryId == null || t.categoryId == selectedCategoryId;

        // Cocokkan tipe transaksi (pemasukan atau pengeluaran)
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
          // Filter bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Button Pilih Tanggal
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
                // Dropdown Jenis Transaksi
                DropdownButton<String>(
                  value: selectedType ?? 'Semua',
                  items: const [
                    DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                    DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                    DropdownMenuItem(value: 'Semua', child: Text('Semua Tipe')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedType = val == 'Semua' ? null : val;
                      selectedCategoryId = null; // Reset kategori saat tipe berubah
                      filterTransactions();
                    });
                  },
                ),
                const SizedBox(width: 16),
                // Dropdown Kategori
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

          // Daftar Transaksi
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text('Tidak ada transaksi.'))
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final t = filteredTransactions[index];

                      // Parse format: Sun, 13 Apr 2025 13:44:05 GMT
                      final rawDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parse(t.date);
                      final formattedDate = DateFormat('dd MMM yyyy • HH:mm').format(rawDate);

                      return ListTile(
                        title: Text(t.description),
                        subtitle: Text('$formattedDate • ${t.categoryName}'),
                        trailing: Text(
                          '${t.type == 'income' ? '+' : '-'} Rp${t.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: t.type == 'income' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
