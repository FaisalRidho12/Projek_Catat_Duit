import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0;
  String _description = '';
  int? _selectedCategoryId;
  String _selectedType = 'income';
  List<Category> _categories = [];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void loadCategories() async {
    final allCategories = await ApiService.getCategories();
    setState(() {
      _categories = allCategories;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories =
        _categories.where((c) => c.type == _selectedType).toList();

    String getFormattedDate() {
      if (_selectedDate == null) return 'Pilih Tanggal';
      return DateFormat('dd MMM yyyy').format(_selectedDate!);
    }

    String getFormattedTime() {
      if (_selectedTime == null) return 'Pilih Waktu';
      final hour = _selectedTime!.hour.toString().padLeft(2, '0');
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedType = val!;
                    _selectedCategoryId = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Jenis Transaksi'),
              ),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                items: filteredCategories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                onSaved: (val) => _description = val ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(getFormattedDate()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(getFormattedTime()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Simpan'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _saveTransaction() async {
    _formKey.currentState!.save();
    if (_selectedCategoryId == null) return;

    // Gabungkan tanggal dan waktu
    final now = DateTime.now();
    final date = _selectedDate ?? now;
    final time = _selectedTime ?? TimeOfDay.fromDateTime(now);
    final combinedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(combinedDateTime);

    print('Tanggal dikirim ke server: $formattedDate');

    final success = await ApiService.addTransaction(
      amount: _amount,
      description: _description,
      date: formattedDate,
      categoryId: _selectedCategoryId!,
    );

    if (success) {
      Navigator.pop(context);
    }
  }
}
