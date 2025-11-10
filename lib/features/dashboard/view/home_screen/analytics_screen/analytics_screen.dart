import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/features/wallet/models/expense_model.dart';
import 'package:expense_tracker/features/wallet/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  String selectedPeriod = "Weekly";
  String selectedType = "Expense";
  late AnimationController _fadeController;
  final db = DBHelper();
  List<ExpenseModel> expenseList = [];
  List<IncomeModel> incomeList = [];
  bool isLoading = true;
  double initialBudget = 0.0;

  @override
  void initState() {
    super.initState();
    loadData();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  Future<void> loadData() async {
    try {
      setState(() => isLoading = true);
      expenseList = await db.getExpenses();
      incomeList = await db.getAllIncome();
      initialBudget = await db.getBudget() ?? 0.0;
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  double get totalIncome =>
      initialBudget + incomeList.fold(0.0, (sum, item) => sum + item.amount);
  double get totalExpense =>
      expenseList.fold(0.0, (sum, item) => sum + item.amount);
  double get balance => totalIncome - totalExpense;

  Map<String, Map<String, double>> _getData(String period) {
    Map<String, double> expenseData = {}, incomeData = {};
    final now = DateTime.now();

    if (period == "Weekly") {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (var day in days) {
        expenseData[day] = 0;
        incomeData[day] = 0;
      }
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      _processData(expenseList, incomeList, expenseData, incomeData, (date) {
        final diff = date.difference(startOfWeek).inDays;
        return diff >= 0 && diff < 7 ? DateFormat('E').format(date) : null;
      });
    } else if (period == "Monthly") {
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM').format(month);
        expenseData[key] = 0;
        incomeData[key] = 0;
      }
      _processData(expenseList, incomeList, expenseData, incomeData, (date) {
        final monthsAgo =
            (now.year - date.year) * 12 + (now.month - date.month);
        return monthsAgo >= 0 && monthsAgo < 12
            ? DateFormat('MMM').format(date)
            : null;
      });
    } else {
      for (int i = 4; i >= 0; i--) {
        final year = (now.year - i).toString();
        expenseData[year] = 0;
        incomeData[year] = 0;
      }
      _processData(expenseList, incomeList, expenseData, incomeData, (date) {
        final year = date.year.toString();
        return expenseData.containsKey(year) ? year : null;
      });
    }
    return {'expense': expenseData, 'income': incomeData};
  }

  void _processData(
    List<ExpenseModel> expenses,
    List<IncomeModel> incomes,
    Map<String, double> expenseData,
    Map<String, double> incomeData,
    String? Function(DateTime) getKey,
  ) {
    for (var expense in expenses) {
      try {
        final date = DateFormat('d/M/yyyy').parse(expense.date);
        final key = getKey(date);
        if (key != null)
          expenseData[key] = (expenseData[key] ?? 0) + expense.amount;
      } catch (_) {}
    }
    for (var income in incomes) {
      try {
        final date = DateFormat('d/M/yyyy').parse(income.date);
        final key = getKey(date);
        if (key != null)
          incomeData[key] = (incomeData[key] ?? 0) + income.amount;
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      appBar: AppBar(
        backgroundColor: ColorConstants.navy,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorConstants.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Analytics",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: ColorConstants.white,
          ),
        ),
      ),
      body: isLoading
          ? _buildShimmerLoading()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildPeriodTabs(),
                      const SizedBox(height: 24),
                      _buildChart(),
                      const SizedBox(height: 24),
                      _buildInsights(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: ColorConstants.grey!,
      highlightColor: ColorConstants.grey!,
      child: Container(height: 200, color: ColorConstants.white),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Income",
                  totalIncome,
                  ColorConstants.green,
                  Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Expense",
                  totalExpense,
                  ColorConstants.red,
                  Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          SizedBox(height: 10),
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: balance >= 0 ? ColorConstants.blue : ColorConstants.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Balance",
                  style: GoogleFonts.inter(color: ColorConstants.white),
                ),
                Text(
                  "₹${balance.toStringAsFixed(0)}",
                  style: GoogleFonts.inter(
                    color: ColorConstants.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  balance >= 0
                      ? Icons.account_balance_wallet
                      : Icons.warning_rounded,
                  color: ColorConstants.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorConstants.white),
          const SizedBox(height: 8),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: GoogleFonts.inter(
              color: ColorConstants.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              color: ColorConstants.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.blues50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: ["Weekly", "Monthly", "Yearly"].map((p) {
              final selected = selectedPeriod == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedPeriod = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? ColorConstants.navy
                          : ColorConstants.blues50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? ColorConstants.white
                            : ColorConstants.grey,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final data = _getData(selectedPeriod);
    final labels = data['expense']!.keys.toList();
    final expenseData = data['expense']!;
    final incomeData = data['income']!;

    final maxValue = [
      ...expenseData.values,
      ...incomeData.values,
    ].fold(0.0, (a, b) => a > b ? a : b);
    final normalizedMax = (maxValue.toDouble() / 1000).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _buildLineChart(labels, expenseData, incomeData, normalizedMax),
      ),
    );
  }

  Widget _buildLineChart(
    List<String> labels,
    Map<String, double> expenseData,
    Map<String, double> incomeData,
    double maxY,
  ) {
    // Determine which lines to show based on selectedType
    List<LineChartBarData> lines = [];

    if (selectedType == "Expense" || selectedType == "Both") {
      lines.add(_line(expenseData, labels, ColorConstants.red, "Expense"));
    }

    if (selectedType == "Income" || selectedType == "Both") {
      lines.add(_line(incomeData, labels, ColorConstants.green, "Income"));
    }

    return LineChart(
      LineChartData(
        maxY: maxY <= 0 ? 5 : maxY,
        minY: 0,
        lineBarsData: lines,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY <= 0 ? 1 : maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: ColorConstants.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${(value * 1000).toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: ColorConstants.grey,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: ColorConstants.grey,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touched) => ColorConstants.navy.withOpacity(0.9),
            getTooltipItems: (spots) => spots.map((sp) {
              final label = sp.barIndex == 0
                  ? (selectedType == "Income" ? "Income" : "Expense")
                  : "Income";
              return LineTooltipItem(
                "$label\n₹${(sp.y * 1000).toStringAsFixed(0)}",
                GoogleFonts.inter(
                  color: ColorConstants.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  LineChartBarData _line(
    Map<String, double> data,
    List<String> labels,
    Color color,
    String type,
  ) {
    return LineChartBarData(
      spots: List.generate(labels.length, (i) {
        final val = (data[labels[i]] ?? 0).toDouble() / 1000;
        return FlSpot(i.toDouble(), val);
      }),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: ColorConstants.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _buildInsights() {
    final data = _getData(selectedPeriod);
    final eTotal = data['expense']!.values.fold(0.0, (a, b) => a + b);
    final iTotal = data['income']!.values.fold(0.0, (a, b) => a + b);
    final label = selectedPeriod == 'Weekly'
        ? 'Daily'
        : selectedPeriod == 'Monthly'
        ? 'Monthly'
        : 'Yearly';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInsightCard(
            "Avg $label Expense",
            eTotal / data['expense']!.length,
            ColorConstants.red,
            Icons.trending_down,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            "Avg $label Income",
            iTotal / data['income']!.length,
            ColorConstants.green,
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ColorConstants.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13)),
              Text(
                "₹${value.toStringAsFixed(0)}",
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
