import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class CategoryDetailPage extends StatelessWidget {
  final String categoryName;
  final List<FinanceTransaction> transactions;

  const CategoryDetailPage({super.key, 
    required this.categoryName,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final categoryTransactions = transactions
        .where((t) => t.categoryName == categoryName)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Detail: $categoryName')),
      body: ListView.builder(
        itemCount: categoryTransactions.length,
        itemBuilder: (context, index) {
          final t = categoryTransactions[index];
          final parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(t.date);
          final formattedDate = DateFormat('dd MMM yyyy • HH:mm').format(parsedDate);

          return ListTile(
            title: Text(t.description),
            subtitle: Text(formattedDate),
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
    );
  }
}
