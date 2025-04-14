import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class EditTransactionPage extends StatefulWidget {
  final FinanceTransaction transaction;

  const EditTransactionPage({super.key, required this.transaction});

  @override
  _EditTransactionPageState createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  DateTime? _selectedDate;
  String? _selectedType;
  int? _selectedCategoryId;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(
      text: NumberFormat.decimalPattern('id')
          .format(widget.transaction.amount),
    );
    _selectedType = widget.transaction.type;
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
        .parse(widget.transaction.date);
    loadCategories();
  }

  void loadCategories() async {
    final data = await ApiService.getCategories();
    setState(() {
      _categories = data;
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && _selectedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate!.hour,
          _selectedDate!.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
    );
    if (pickedTime != null && _selectedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() &&
        _selectedType != null &&
        _selectedCategoryId != null &&
        _selectedDate != null) {
      final updatedTransaction = FinanceTransaction(
        id: widget.transaction.id,
        description: _descriptionController.text,
        amount: NumberFormat.decimalPattern('id')
            .parse(_amountController.text.replaceAll('.', ''))
            .toDouble(),
        date: DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDate!),
        type: _selectedType!,
        categoryId: _selectedCategoryId!,
        categoryName: '',
      );

      final success = await ApiService.updateTransaction(updatedTransaction);

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui transaksi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories =
        _categories.where((c) => c.type == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  try {
                    final raw = value.replaceAll('.', '');
                    final number = NumberFormat.decimalPattern('id').parse(raw);
                    final formatted = NumberFormat.decimalPattern('id').format(number);
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  } catch (_) {}
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Jumlah wajib diisi';
                  try {
                    final parsed = NumberFormat.decimalPattern('id')
                        .parse(value.replaceAll('.', ''));
                    if (parsed <= 0) return 'Masukkan jumlah yang valid';
                  } catch (e) {
                    return 'Format jumlah tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedType = val;
                    _selectedCategoryId = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tipe Transaksi'),
                validator: (value) =>
                    value == null ? 'Pilih tipe transaksi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                items: filteredCategories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                decoration: const InputDecoration(labelText: 'Kategori'),
                validator: (value) => value == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate == null
                        ? 'Pilih Tanggal'
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.date_range),
                    label: const Text('Pilih Tanggal'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate == null
                        ? 'Pilih Jam'
                        : DateFormat('HH:mm').format(_selectedDate!),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: const Text('Pilih Jam'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Simpan'),
                onPressed: _saveTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
