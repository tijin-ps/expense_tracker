import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/database/category_db.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/core/constants/image_constants.dart';
import 'package:expense_tracker/features/dashboard/models/category_model.dart';
import 'package:expense_tracker/features/wallet/models/expense_model.dart';
import 'package:expense_tracker/features/wallet/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen>
    with TickerProviderStateMixin {
  String selectedValue = "Expense";
  String selectedFilter = "All";
  String sortBy = "Highest First";
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final db = DBHelper();
  List<ExpenseModel> expenseList = [];
  List<IncomeModel> incomeList = [];
  bool isLoading = true;
  double initialBudget = 0.0;
  List<CategoryModel> categoryList = [];

  @override
  void initState() {
    super.initState();
    loadData();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  Future<void> loadData() async {
    try {
      if (mounted) setState(() => isLoading = true);
      // Use Future.wait for parallel fetching
      final results = await Future.wait([
        db.getExpenses(),
        db.getAllIncome(),
        db.getBudget(),
        CategoryDB.instance.fetchCategories(),
      ]);
      expenseList = results[0] as List<ExpenseModel>;
      incomeList = results[1] as List<IncomeModel>;
      initialBudget = (results[2] as double?) ?? 0.0;
      categoryList = results[3] as List<CategoryModel>;
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  double get totalIncome =>
      initialBudget + incomeList.fold(0, (sum, item) => sum + item.amount);

  double get totalExpense =>
      expenseList.fold(0, (sum, item) => sum + item.amount);

  // Get filtered and sorted list
  List<dynamic> getFilteredAndSortedList() {
    final bool isExpenseView = selectedValue == "Expense";
    List<dynamic> list = isExpenseView
        ? List<dynamic>.from(expenseList)
        : List<dynamic>.from(incomeList);

    // Filter by category
    if (selectedFilter != "All") {
      list = list.where((item) => item.category == selectedFilter).toList();
    }

    // Sort the list
    switch (sortBy) {
      case "Highest First":
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case "Lowest First":
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case "By Date":
        list.sort((a, b) {
          try {
            final dateA = DateFormat('dd-MM-yyyy').parse(a.date);
            final dateB = DateFormat('dd-MM-yyyy').parse(b.date);
            return dateB.compareTo(dateA); // Most recent first
          } catch (e) {
            return 0;
          }
        });
        break;
    }

    return list;
  }

  // Calculate weekly data from actual expenses/income
  Map<String, double> getWeeklyData() {
    final bool isExpenseView = selectedValue == "Expense";
    final list = isExpenseView ? expenseList : incomeList;

    Map<String, double> weeklyData = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (dynamic item in list) {
      try {
        final itemDate = DateFormat('d/M/yyyy').parse(item.date);
        final daysDiff = itemDate.difference(startOfWeek).inDays;

        if (daysDiff >= 0 && daysDiff < 7) {
          final dayName = DateFormat('E').format(itemDate);
          weeklyData[dayName] = (weeklyData[dayName] ?? 0) + item.amount;
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    // If viewing income for the current week, add the initial budget
    if (!isExpenseView) {
      weeklyData.values.reduce((a, b) => a + b);
      weeklyData['Mon'] = (weeklyData['Mon'] ?? 0) + initialBudget;
    }

    return weeklyData;
  }

  CategoryModel _getCategoryForName(String name, {bool isExpense = true}) {
    return categoryList.firstWhere(
      (cat) => cat.name == name,
      orElse: () => CategoryModel(
        name: 'Other',
        iconCode: Icons.payments_rounded.codePoint,
        colorCode: isExpense
            ? ColorConstants.red.value
            : ColorConstants.green.value,
      ),
    );
  }

  IconData getIcon(int codePoint) {
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  Color getColor(int colorCode) {
    return Color(colorCode);
  }

  List<Color> getGradient(int colorCode, {bool isExpense = true}) {
    final color = getColor(colorCode);
    if (isExpense) {
      // Create a slightly different shade for the gradient
      return [color, Color.lerp(color, Colors.black, 0.2)!];
    } else {
      return [color, Color.lerp(color, Colors.white, 0.3)!];
    }
  }

  Color getCategoryColor(String categoryName, {bool isExpense = true}) {
    if (categoryName == "All") {
      return isExpense ? ColorConstants.red : ColorConstants.green;
    }
    final category = categoryList.firstWhere((cat) => cat.name == categoryName);
    return getColor(category.colorCode);
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpenseView = selectedValue == "Expense";
    return Scaffold(
      backgroundColor: ColorConstants.white,
      appBar: AppBar(
        backgroundColor: ColorConstants.navy,
        centerTitle: true,
        title: Text(
          "Statistics",
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildControlsRow(),
                      const SizedBox(height: 28),
                      _buildWeeklyOverview(),
                      const SizedBox(height: 28),
                      if ((isExpenseView && expenseList.isNotEmpty) ||
                          (!isExpenseView && incomeList.isNotEmpty))
                        _buildTopSpendingHeader(),
                      _buildCategoryFilter(),
                      const SizedBox(height: 10),
                      _buildSpendingList(),
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
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Shimmer for _buildControlsRow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Shimmer for _buildWeeklyOverview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 180,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Shimmer for list items
                ...List.generate(3, (index) => _buildShimmerListItem()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stats Summary Cards
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    color: ColorConstants.white,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${totalIncome.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(
                      color: ColorConstants.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Income",
                    style: GoogleFonts.inter(
                      color: ColorConstants.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    color: ColorConstants.white,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${totalExpense.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(
                      color: ColorConstants.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Expense",
                    style: GoogleFonts.inter(
                      color: ColorConstants.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Expense/Income Dropdown
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Already a constant
            FilterChip(
              label: const Text("All"),
              selected: selectedFilter == "All",
              onSelected: (_) => setState(() => selectedFilter = "All"),
              // ... styles for "All" chip
            ),
            const SizedBox(width: 10),
            for (var category in categoryList)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text(category.name),
                  selected: selectedFilter == category.name,
                  onSelected: (_) =>
                      setState(() => selectedFilter = category.name),
                  backgroundColor: ColorConstants.white,
                  selectedColor: getColor(category.colorCode).withOpacity(0.15),
                  checkmarkColor: getColor(category.colorCode),
                  labelStyle: GoogleFonts.inter(
                    fontWeight: selectedFilter == category.name
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: selectedFilter == category.name
                        ? getColor(category.colorCode)
                        : ColorConstants.grey,
                  ),
                  side: BorderSide(
                    color: selectedFilter == category.name
                        ? getColor(category.colorCode)
                        : ColorConstants.grey,
                    width: selectedFilter == category.name ? 1.5 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    final weeklyData = getWeeklyData();
    final maxValue = weeklyData.values.reduce((a, b) => a > b ? a : b);
    final normalizedMax = (maxValue / 1000).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Weekly Overview",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: ColorConstants.navy,
                ),
              ),
              _buildTypeToggle(),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white, // Already a constant
              borderRadius: BorderRadius.circular(24),
              // Added box shadow for depth, can be customized
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.navy.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: normalizedMax > 0 ? normalizedMax : 5,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    // Already a constant
                    color: ColorConstants.gainsboro.withOpacity(0.5),
                    strokeWidth: 1.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}k',
                          style: GoogleFonts.inter(
                            // Already a constant
                            fontSize: 12,
                            color: ColorConstants.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = [
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                          "Sun",
                        ];
                        if (value.toInt() < labels.length) {
                          return Text(
                            // Already a constant
                            labels[value.toInt()],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ColorConstants.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  const days = [
                    "Mon",
                    "Tue",
                    "Wed",
                    "Thu",
                    "Fri",
                    "Sat",
                    "Sun",
                  ];
                  final amount = weeklyData[days[index]] ?? 0;
                  final normalizedAmount = amount / 1000;
                  final colors = [
                    ColorConstants.blue,
                    ColorConstants.purple,
                    ColorConstants.teal,
                    ColorConstants.orange,
                    ColorConstants.green,
                    ColorConstants.jellyBeanBlue,
                    ColorConstants.gold,
                  ];
                  return _buildBarGroup(index, normalizedAmount, colors[index]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorConstants.blues50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildToggleItem("Expense"), _buildToggleItem("Income")],
      ),
    );
  }

  Widget _buildToggleItem(String title) {
    final bool isSelected = selectedValue == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedValue = title; // Already a constant
          selectedFilter = "All"; // Reset filter
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          // Already a constant
          color: isSelected
              ? ColorConstants.white
              : Colors.transparent, // Already a constant
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorConstants.navy.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected
                ? FontWeight.w700
                : FontWeight.w500, // Already a constant
            color: isSelected ? ColorConstants.navy : ColorConstants.grey,
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color, color.withOpacity(0.7)],
          ),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(1),
            topRight: Radius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSpendingHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selectedValue == "Expense" ? "Top Spending" : "Top Earnings",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: ColorConstants.navy,
            ),
          ),
          // Use Material for ink splash effect and shape
          Material(
            color: ColorConstants.navy,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _showSortModal(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                // Already a constant
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: ColorConstants.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingList() {
    final bool isExpenseView = selectedValue == "Expense";
    final list = getFilteredAndSortedList();
    final totalAmount = isExpenseView ? totalExpense : totalIncome;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(ImageConstants.aboutLottie, height: 200, width: 200),
              const SizedBox(height: 20),
              Text(
                selectedFilter != "All"
                    ? "No ${isExpenseView ? 'expenses' : 'incomes'} found in '$selectedFilter'"
                    : "No ${isExpenseView ? 'expenses' : 'incomes'} yet.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.navy.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final dynamic item = list[index];
        final category = _getCategoryForName(
          item.category,
          isExpense: isExpenseView,
        );
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(40 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: child,
              ), // Already a constant
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(24), // Already a constant
              border: Border.all(
                color: ColorConstants.gainsboro.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.navy.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: getGradient(
                        category.colorCode,
                        isExpense: isExpenseView,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    getIcon(category.iconCode),
                    color: ColorConstants.white,
                    size: 30, // Already a constant
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: ColorConstants.navy,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ), // Already a constant
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹${item.amount.toStringAsFixed(0)}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isExpenseView
                                  ? ColorConstants.red
                                  : ColorConstants.green,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: ColorConstants.gainsboro.withOpacity(
                                  0.5,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment:
                                    Alignment.centerLeft, // Already a constant
                                widthFactor: totalAmount > 0
                                    ? (item.amount / totalAmount)
                                    : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      // Already a constant
                                      colors: getGradient(
                                        category.colorCode,
                                        isExpense: isExpenseView,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${totalAmount > 0 ? ((item.amount / totalAmount) * 100).toStringAsFixed(0) : 0}%",
                            style: GoogleFonts.inter(
                              color: ColorConstants.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConstants.blues50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.date,
                                  style: GoogleFonts.inter(
                                    color: ColorConstants.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorConstants.blue, ColorConstants.jellyBeanBlue],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ColorConstants.navy, ColorConstants.blue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sort_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Sort By",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.navy,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSortOption("Highest First", Icons.arrow_downward_rounded),
            _buildSortOption("Lowest First", Icons.arrow_upward),
            _buildSortOption("By Date", Icons.calendar_today),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
    bool isSelected = sortBy == title;
    return InkWell(
      onTap: () {
        setState(() {
          sortBy = title; // Already a constant
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstants.blues50
              : Colors.transparent, // Already a constant
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? ColorConstants.navy : ColorConstants.grey,
            ),
            const SizedBox(width: 12),
            Text(
              title, // Already a constant
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w500, // Already a constant
                color: isSelected ? ColorConstants.navy : ColorConstants.grey,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: ColorConstants.navy, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerListItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ColorConstants.gainsboro.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Container(height: 60, color: Colors.white)),
        ],
      ),
    );
  }
}
