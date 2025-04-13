class FinanceTransaction {
  final int id;
  final double amount;
  final String description;
  final String date;
  final int categoryId;
  final String categoryName;
  final String type;

  FinanceTransaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    required this.type,
  });

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      description: json['description'],
      date: json['date'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      type: json['type'],
    );
  }
}
