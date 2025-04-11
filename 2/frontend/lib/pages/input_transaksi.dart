import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class InputTransaksiPage extends StatefulWidget {
  const InputTransaksiPage({super.key});

  @override
  State<InputTransaksiPage> createState() => _InputTransaksiPageState();
}

class _InputTransaksiPageState extends State<InputTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  String jenis = 'pemasukan';
  int jumlah = 0;
  String keterangan = '';
  final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());

Future<void> submit() async {
  print('Submit ditekan');
  if (_formKey.currentState!.validate()) {
    print('Form valid');
    final success = await ApiService.tambahTransaksi(jenis, jumlah, keterangan); // Hapus 'tanggal'
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan transaksi')),
      );
    }
  }
  else {
    print('Form tidak valid');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Transaksi")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: jenis,
                decoration: const InputDecoration(labelText: "Jenis"),
                items: const [
                  DropdownMenuItem(value: "pemasukan", child: Text("Pemasukan")),
                  DropdownMenuItem(value: "pengeluaran", child: Text("Pengeluaran")),
                ],
                onChanged: (val) => setState(() => jenis = val!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Jumlah"),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                onChanged: (val) => jumlah = int.tryParse(val) ?? 0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Keterangan"),
                onChanged: (val) => keterangan = val,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submit,
                child: const Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
