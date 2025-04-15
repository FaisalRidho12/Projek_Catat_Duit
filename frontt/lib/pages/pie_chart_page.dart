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
  DateTime? selectedDate;
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
    setState(() {
      filteredTransactions = allTransactions.where((t) {
        final date =
            DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parse(t.date);
        switch (selectedFilter) {
          case 'Harian':
            if (selectedDate == null) return false;
            return date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;
          case 'Bulanan':
            if (selectedDate == null) return false;
            return date.year == selectedDate!.year &&
                date.month == selectedDate!.month;
          case 'Tahunan':
            if (selectedDate == null) return false;
            return date.year == selectedDate!.year;
          case 'Keseluruhan':
          default:
            return true;
        }
      }).toList();
    });
  }

  Future<void> pickFilterDate(BuildContext context) async {
    DateTime now = DateTime.now();

    switch (selectedFilter) {
      case 'Harian':
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          selectedDate = picked;
          applyFilter();
        }
        break;

      case 'Bulanan':
        int selectedMonth = now.month;
        int selectedYear = now.year;

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Pilih Bulan & Tahun'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // pilihan untuk bulan
                  DropdownButton<int>(
                    value: selectedMonth,
                    onChanged: (val) {
                      if (val != null) {
                        selectedMonth = val;
                        setState(() {});
                      }
                    },
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM', 'id')
                                  .format(DateTime(0, m))),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  // pilihan untuk tahun
                  DropdownButton<int>(
                    value: selectedYear,
                    onChanged: (val) {
                      if (val != null) {
                        selectedYear = val;
                        setState(() {});
                      }
                    },
                    items: List.generate(30, (i) => now.year - 15 + i)
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    selectedDate = DateTime(selectedYear, selectedMonth);
                    applyFilter();
                    Navigator.pop(context);
                  },
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
        break;

      case 'Tahunan':
        int? pickedYear;

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Pilih Tahun'),
              content: DropdownButton<int>(
                value: pickedYear ?? now.year,
                onChanged: (val) => pickedYear = val,
                items: List.generate(30, (i) => now.year - 15 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    if (pickedYear != null) {
                      selectedDate = DateTime(pickedYear!);
                      applyFilter();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
        break;
    }
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
              onChanged: (val) async {
                if (val != null) {
                  selectedFilter = val;
                  if (val != 'Keseluruhan') {
                    await pickFilterDate(context);
                  } else {
                    selectedDate = null;
                    applyFilter();
                  }
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
    if (dataMap.isEmpty) {
      return const Center(
        child: Text('Tidak ada data transaksi untuk ditampilkan'),
      );
    }

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
          color: const Color.fromARGB(255, 60, 58, 58),
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
                    final index =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;

                    if (index >= 0 && index < entries.length) {
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
                                .where((tx) =>
                                    tx.type == type &&
                                    tx.categoryName == selectedCategory)
                                .toList(),
                          ),
                        ),
                      );
                    }
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
            child: filteredTransactions.isEmpty
                ? const Center(child: Text('Tidak ada data untuk grafik'))
                : LineChart(_buildLineChartData(type)),
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(String type) {
    final Map<DateTime, double> dailyData = {};
    final Map<DateTime, String> labelData =
        {}; // Simpan label kategori terakhir

    for (var t in filteredTransactions.where((tx) => tx.type == type)) {
      final date =
          DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parse(t.date);
      final day = DateTime(date.year, date.month, date.day);
      dailyData[day] = (dailyData[day] ?? 0) + t.amount;
      labelData[day] = t.categoryName; // untuk nyimpen kategori pd tgl tersebut
    }

    if (dailyData.isEmpty) {
      return LineChartData(); // biar aman pas ga ada data
    }

    final sortedDates = dailyData.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      int x = entry.key;
      DateTime date = entry.value;
      return FlSpot(x.toDouble(), dailyData[date]!);
    }).toList();

    final isPemasukan = type == 'Pemasukan';
    final lineColor = isPemasukan
        ? const Color.fromARGB(255, 44, 104, 182)
        : const Color.fromARGB(255, 54, 193, 244);

    return LineChartData(
      minY: 0,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) => Text(
              NumberFormat.decimalPattern('id')
                  .format(value), // format angka/nominalnya
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value >= sortedDates.length) return Container();
              final date = sortedDates[value.toInt()];
              final label = DateFormat('d MMM', 'id').format(date);
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(label, style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.black.withOpacity(0.7),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = sortedDates[spot.x.toInt()];
              final formattedDate = DateFormat('d MMM yyyy', 'id').format(date);
              final formattedValue =
                  NumberFormat.decimalPattern('id').format(spot.y);
              final category = labelData[date] ?? '';
              return LineTooltipItem(
                '$formattedDate\nKategori: $category\nRp $formattedValue',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
      gridData: const FlGridData(
          show: true, drawVerticalLine: true, drawHorizontalLine: true),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
