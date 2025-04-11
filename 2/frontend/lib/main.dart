import 'package:flutter/material.dart';
import 'pages/dashboard.dart';
import 'pages/input_transaksi.dart';
import 'pages/riwayat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Keuangan',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const DashboardPage(),
      routes: {
        '/input': (context) => const InputTransaksiPage(),
        '/riwayat': (context) => const RiwayatPage(),
      },
    );
  }
}
