import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List riwayat = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await ApiService.fetchTransaksi();
    setState(() => riwayat = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Transaksi")),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView.builder(
          itemCount: riwayat.length,
          itemBuilder: (context, index) {
            final item = riwayat[index];
            final tanggal = DateFormat('dd-MM-yyyy').format(DateTime.parse(item['tanggal']));
            return ListTile(
              leading: Icon(item['jenis'] == 'pemasukan' ? Icons.arrow_downward : Icons.arrow_upward,
                  color: item['jenis'] == 'pemasukan' ? Colors.green : Colors.red),
              title: Text("Rp ${item['jumlah']}"),
              subtitle: Text("${item['keterangan']} ($tanggal)"),
            );
          },
        ),
      ),
    );
  }
}
