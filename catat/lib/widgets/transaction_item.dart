import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/transaction.dart';

class ApiService {
  static const baseUrl = 'http://localhost:5000';

  static Future<List<FinanceTransaction>> getAllTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));
    final List data = json.decode(response.body);
    return data.map((json) => FinanceTransaction.fromJson(json)).toList();
  }

  static Future<List<FinanceTransaction>> getTodayTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions/today'));
    final List data = json.decode(response.body);
    return data.map((json) => FinanceTransaction.fromJson(json)).toList();
  }

  static Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    final List data = json.decode(response.body);
    return data.map((json) => Category.fromJson(json)).toList();
  }

  static Future<bool> addTransaction({
    required double amount,
    required String description,
    required String date,
    required int categoryId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': amount,
        'description': description,
        'date': date,
        'category_id': categoryId,
      }),
    );
    return response.statusCode == 201;
  }
}
