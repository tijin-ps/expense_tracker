import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/database/category_db.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/features/dashboard/models/category_model.dart';
import 'package:expense_tracker/features/wallet/models/expense_model.dart';
import 'package:expense_tracker/features/wallet/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedPeriod = 'Weekly';
  bool _isLoading = true;

  final db = DBHelper();
  List<ExpenseModel> _expenseList = [];
  List<IncomeModel> _incomeList = [];
  List<CategoryModel> _categoryList = [];
  double _initialBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      db.getExpenses(),
      db.getAllIncome(),
      db.getBudget(),
      CategoryDB.instance.fetchCategories(),
    ]);

    if (mounted) {
      setState(() {
        _expenseList = results[0] as List<ExpenseModel>;
        _incomeList = results[1] as List<IncomeModel>;
        _initialBudget = (results[2] as double?) ?? 0.0;
        _categoryList = results[3] as List<CategoryModel>;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- Data Filtering and Calculation Logic ---

  List<T> _filterByPeriod<T>(List<T> transactions) {
    final now = DateTime.now();
    return transactions.where((t) {
      try {
        final date = DateFormat('d/M/yyyy').parse((t as dynamic).date);
        if (_selectedPeriod == 'Weekly') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(startOfWeek.add(const Duration(days: 7)));
        } else if (_selectedPeriod == 'Monthly') {
          return date.year == now.year && date.month == now.month;
        } else if (_selectedPeriod == 'Yearly') {
          return date.year == now.year;
        }
        return true;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<ExpenseModel> get _filteredExpenses => _filterByPeriod(_expenseList);
  List<IncomeModel> get _filteredIncomes => _filterByPeriod(_incomeList);

  double get _totalSpent =>
      _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

  double get _totalIncome =>
      _filteredIncomes.fold(0.0, (sum, item) => sum + item.amount);

  double get _totalBudget {
    // Total budget is the initial budget plus all income (filtered by period).
    return _initialBudget + _totalIncome;
  }

  double get _budgetPercentage =>
      _totalBudget > 0 ? (_totalSpent / _totalBudget) * 100 : 0;

  Map<String, double> get _categorySpending {
    final Map<String, double> spending = {};
    for (var expense in _filteredExpenses) {
      spending[expense.category] =
          (spending[expense.category] ?? 0) + expense.amount;
    }
    return spending;
  }

  CategoryModel _getCategoryDetails(String name) {
    return _categoryList.firstWhere(
      (cat) => cat.name == name,
      orElse: () => CategoryModel(
        name: 'Other',
        iconCode: Icons.category.codePoint,
        colorCode: Colors.grey.value,
      ),
    );
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
          "Budget",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: ColorConstants.white,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                _buildOverviewCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('Budget Categories', 'See All'),
                const SizedBox(height: 16),
                _buildBudgetList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Weekly', 'Monthly', 'Yearly'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ColorConstants.blues50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPeriod = period;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    // Already a constant
                    color: isSelected ? ColorConstants.navy : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      // Already a constant
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? ColorConstants.white
                          : ColorConstants.navy,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.blues50,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget',
                      style: GoogleFonts.inter(
                        color: ColorConstants.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_totalBudget.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: ColorConstants.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConstants.white, // Already a constant
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: ColorConstants.navy,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Spent',
                    '₹${_totalSpent.toStringAsFixed(2)}',
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildOverviewStat(
                    'Remaining',
                    '₹${(_totalBudget - _totalSpent).toStringAsFixed(2)}',
                    Icons.savings_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: // Already a constant
                        _animationController.value * (_budgetPercentage / 100),
                    minHeight: 10,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _budgetPercentage > 90
                          ? ColorConstants.red300
                          : ColorConstants.green300,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_budgetPercentage.toStringAsFixed(1)}% of budget used',
                  style: GoogleFonts.inter(
                    color: ColorConstants.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4, // Already a constant
                  ),
                  decoration: BoxDecoration(
                    color:
                        _budgetPercentage >
                            90 // Already a constant
                        ? ColorConstants.red.withOpacity(0.3)
                        : ColorConstants.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _budgetPercentage > 90 ? 'High Usage' : 'On Track',
                    style: GoogleFonts.inter(
                      color: ColorConstants.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(String label, String amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Already a constant
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorConstants.navy, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(color: ColorConstants.navy, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: ColorConstants.navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700, // Already a constant
              color: const Color(0xFF2D3142),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              action,
              style: GoogleFonts.inter(
                color: const Color(0xFF667eea),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList() {
    final spendingData = _categorySpending;
    final categories = spendingData.keys.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final categoryName = categories[index];
          final spent = spendingData[categoryName]!;
          final categoryDetails = _getCategoryDetails(categoryName);
          final percentage = _totalSpent > 0 ? (spent / _totalSpent) * 100 : 0;
          final isOverBudget = percentage > 50; // Example threshold

          return Container(
            // Already a constant
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorConstants.blues50,
              borderRadius: BorderRadius.circular(20),
              border: isOverBudget
                  ? Border.all(color: ColorConstants.red300, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(
                          categoryDetails.colorCode,
                        ).withOpacity(0.1), // Already a constant
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        IconData(
                          categoryDetails.iconCode,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(categoryDetails.colorCode),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16, // Already a constant
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_filteredExpenses.where((e) => e.category == categoryName).length} transactions',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${spent.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 18, // Already a constant
                            color: isOverBudget
                                ? ColorConstants.red600
                                : const Color(0xFF2D3142),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(
                          categoryDetails.colorCode,
                        ).withOpacity(0.1), // Already a constant
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (percentage / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isOverBudget // Already a constant
                                ? [ColorConstants.red400, ColorConstants.red600]
                                : [
                                    Color(categoryDetails.colorCode),
                                    Color(
                                      categoryDetails.colorCode,
                                    ).withOpacity(0.7),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // Already a constant // Already a constant
                        color: isOverBudget
                            ? ColorConstants.red.withOpacity(0.3)
                            : percentage >
                                  80 // Already a constant
                            ? ColorConstants.orange.withOpacity(0.3)
                            : ColorConstants.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOverBudget
                            ? 'Over Budget'
                            : percentage > 80
                            ? 'Near Limit'
                            : 'On Track',
                        style: GoogleFonts.inter(
                          fontSize: 11, // Already a constant
                          fontWeight: FontWeight.w600,
                          color: isOverBudget
                              ? ColorConstants
                                    .red // Already a constant
                              : percentage >
                                    80 // Already a constant
                              ? ColorConstants.orange
                              : ColorConstants.green,
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600, // Already a constant
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
