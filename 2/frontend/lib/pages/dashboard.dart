import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int saldo = 0;
  int pemasukan = 0;
  int pengeluaran = 0;
  List riwayatHariIni = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final data = await ApiService.fetchDashboard();
    setState(() {
      saldo = data['saldo'];
      pemasukan = data['pemasukan_hari_ini'];
      pengeluaran = data['pengeluaran_hari_ini'];
      riwayatHariIni = data['riwayat_hari_ini'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: const Text("Saldo"),
                subtitle: Text("Rp ${saldo.toString()}"),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green[100],
                    child: ListTile(
                      title: const Text("Pemasukan"),
                      subtitle: Text("Rp $pemasukan"),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: Colors.red[100],
                    child: ListTile(
                      title: const Text("Pengeluaran"),
                      subtitle: Text("Rp $pengeluaran"),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Riwayat Hari Ini",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...riwayatHariIni.map((e) {
              final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.parse(e['tanggal']));
              return ListTile(
                leading: Icon(e['jenis'] == 'pemasukan' ? Icons.arrow_downward : Icons.arrow_upward,
                    color: e['jenis'] == 'pemasukan' ? Colors.green : Colors.red),
                title: Text("Rp ${e['jumlah']}"),
                subtitle: Text("${e['keterangan']} ($tanggal)"),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/input'),
              child: const Text("+ Tambah Transaksi"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/riwayat'),  
              child: const Text("Lihat Semua Riwayat"),
            )
          ],
        ),
      ),
    );
  }
}
