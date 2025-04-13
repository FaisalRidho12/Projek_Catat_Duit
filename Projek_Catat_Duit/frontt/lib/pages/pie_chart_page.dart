import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import 'category_detail_page.dart';

class PieChartPage extends StatefulWidget {
  const PieChartPage({super.key});

  @override
  _PieChartPageState createState() => _PieChartPageState();
}

class _PieChartPageState extends State<PieChartPage> {
  List<FinanceTransaction> allTransactions = [];
  List<FinanceTransaction> filteredTransactions = [];
  String selectedFilter = 'Keseluruhan';
  int? touchedIndex;

  final List<Color> chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.teal,
    Colors.cyan,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final data = await ApiService.getAllTransactions();
    setState(() {
      allTransactions = data;
      applyFilter();
    });
  }

  void applyFilter() {
    DateTime now = DateTime.now();

    setState(() {
      filteredTransactions = allTransactions.where((t) {
        final date = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parse(t.date);
        switch (selectedFilter) {
          case 'Harian':
            return date.year == now.year && date.month == now.month && date.day == now.day;
          case 'Bulanan':
            return date.year == now.year && date.month == now.month;
          case 'Tahunan':
            return date.year == now.year;
          case 'Keseluruhan':
          default:
            return true;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeMap = <String, double>{};
    final expenseMap = <String, double>{};

    for (var t in filteredTransactions) {
      final map = t.type == 'income' ? incomeMap : expenseMap;
      map[t.categoryName] = (map[t.categoryName] ?? 0) + t.amount;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistik Transaksi'),
          actions: [
            DropdownButton<String>(
              value: selectedFilter,
              onChanged: (val) {
                if (val != null) {
                  selectedFilter = val;
                  applyFilter();
                }
              },
              items: ['Keseluruhan', 'Harian', 'Bulanan', 'Tahunan']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pemasukan'),
              Tab(text: 'Pengeluaran'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChartPage(incomeMap, 'income'),
            _buildChartPage(expenseMap, 'expense'),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPage(Map<String, double> dataMap, String type) {
    final total = dataMap.values.fold(0.0, (a, b) => a + b);
    final entries = dataMap.entries.toList();

    final pieSections = entries.asMap().entries.map((entry) {
      int i = entry.key;
      var e = entry.value;
      double percentage = (e.value / total) * 100;

      return PieChartSectionData(
        color: chartColors[i % chartColors.length],
        value: e.value,
        title: '${e.key} (${percentage.toStringAsFixed(1)}%)',
        radius: touchedIndex == i ? 90 : 80,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: touchedIndex == i ? 16 : 14,
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  if (pieTouchResponse != null &&
                    pieTouchResponse.touchedSection != null &&
                    (event is FlTapUpEvent || event is FlLongPressEnd)) {
                    final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    final selectedCategory = entries[index].key;

                    setState(() {
                      touchedIndex = index;
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailPage(
                          categoryName: selectedCategory,
                          transactions: filteredTransactions
                              .where((tx) => tx.type == type && tx.categoryName == selectedCategory)
                              .toList(),
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      touchedIndex = -1;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        const Divider(),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LineChart(_buildLineChartData(type)),
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(String type) {
    final Map<DateTime, double> dailyData = {};

    for (var t in filteredTransactions.where((tx) => tx.type == type)) {
      final date = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parse(t.date);
      final day = DateTime(date.year, date.month, date.day);
      dailyData[day] = (dailyData[day] ?? 0) + t.amount;
    }

    final sortedDates = dailyData.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      int x = entry.key;
      DateTime date = entry.value;
      return FlSpot(x.toDouble(), dailyData[date]!);
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('Rp ${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value >= sortedDates.length) return Container();
              final date = sortedDates[value.toInt()];
              return Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10));
            },
            interval: 1,
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: type == 'income' ? Colors.green : Colors.red,
          barWidth: 2,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: (type == 'income' ? Colors.greenAccent : Colors.redAccent).withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
