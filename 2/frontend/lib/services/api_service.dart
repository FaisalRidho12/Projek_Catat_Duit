import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaksi.dart';

const String baseUrl = 'http://192.168.1.4:5000';


class ApiService {
  static Future<List<Transaksi>> fetchTransaksi() async {
    final response = await http.get(Uri.parse('$baseUrl/transaksi'));
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Transaksi.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard'));
    return jsonDecode(response.body);
  }

  static Future<bool> tambahTransaksi(String jenis, int jumlah, String keterangan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jenis': jenis,
        'jumlah': jumlah,
        'keterangan': keterangan,
        // Hapus 'tanggal'
      }),
    );
    return response.statusCode == 201;
  }
}
