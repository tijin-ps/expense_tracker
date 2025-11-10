import 'dart:io';
import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/features/auth/view/login/login_screen.dart';
import 'package:expense_tracker/core/constants/image_constants.dart';
import 'package:expense_tracker/core/database/category_db.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/features/dashboard/view/home_screen/analytics_screen/analytics_screen.dart';
import 'package:expense_tracker/features/dashboard/view/home_screen/banner_list.dart';
import 'package:expense_tracker/features/dashboard/view/home_screen/budget/budgetscreen.dart';
import 'package:expense_tracker/features/dashboard/view/home_screen/my_cards/my_cards.dart';
import 'package:expense_tracker/features/dashboard/view/home_screen/category/category_screen.dart';
import 'package:expense_tracker/features/wallet/models/income_model.dart';
import 'package:expense_tracker/features/dashboard/models/category_model.dart';
import 'package:expense_tracker/features/wallet/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int activeIndex = 0;
  int selectedCategoryIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final db = DBHelper();
  List<IncomeModel> incomeList = [];
  List<ExpenseModel> expenseList = [];
  bool isLoading = true;
  String selectedFilter = "All";
  String? userName;
  String? imagePath;
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
    // Added a delay to make the shimmer effect visible during development
    await Future.delayed(const Duration(seconds: 2));
    incomeList = await db.getAllIncome();
    expenseList = await db.getExpenses();
    initialBudget = await db.getBudget() ?? 0.0;
    categoryList = await CategoryDB.instance.fetchCategories();

    final profileData = await db.getProfile();
    if (profileData != null) {
      userName =
          "${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}"
              .trim();
      imagePath = profileData['image_path'];
    }
    if (mounted) {
      setState(() => isLoading = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowBudgetSheet();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Declare globally in your State class
  // In your State class
  final TextEditingController budgetController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> _checkAndShowBudgetSheet() async {
    final budget = await db.getBudget();
    if (budget == null) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildBudgetBottomSheet(context),
      );

      if (result != true) {
        // User tried to dismiss without saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("You must set an initial budget to continue."),
            backgroundColor: ColorConstants.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Widget _buildBudgetBottomSheet(BuildContext modalContext) {
    // choose a height factor (0.35 = 35% of screen height) — adjust as needed
    const double heightFactor = 0.50;

    // Get keyboard inset
    final keyboardInset = MediaQuery.of(modalContext).viewInsets.bottom;

    return AnimatedPadding(
      // AnimatedPadding makes the move up/down smooth
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: heightFactor, // keeps sheet height fixed (doesn't expand)
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            // Provide material so elevation / background looks correct
            color: Theme.of(modalContext).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              // this allows internal scrolling if content is taller
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header row
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: ColorConstants.navy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: ColorConstants.navy,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Set Your Budget",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Please set your initial budget to start tracking your expenses.",
                      style: GoogleFonts.inter(color: ColorConstants.grey),
                    ),
                    const SizedBox(height: 20),

                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: budgetController,
                        autofocus: true,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: "Budget Amount",
                          prefixText: "₹",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter a budget';
                          final parsed = double.tryParse(
                            value.replaceAll(',', ''),
                          );
                          if (parsed == null || parsed <= 0)
                            return 'Please enter a valid amount';
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final val = double.parse(
                              budgetController.text.replaceAll(',', ''),
                            );
                            await db.saveBudget(val);
                            Navigator.of(modalContext).pop(true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Save Budget",
                          style: GoogleFonts.inter(
                            color: ColorConstants.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double get totalIncome =>
      incomeList.fold(0, (sum, item) => sum + item.amount);

  double get totalExpense =>
      expenseList.fold(0, (sum, item) => sum + item.amount);

  double get totalBalance => initialBudget + totalIncome - totalExpense;

  CategoryModel _getCategoryForName(String name, {bool isExpense = false}) {
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

  List<Color> getGradient(int colorCode, {bool isExpense = false}) {
    final color = getColor(colorCode);
    if (isExpense) {
      // Create a slightly different shade for the gradient
      return [color, Color.lerp(color, Colors.black, 0.2)!];
    } else {
      return [color, Color.lerp(color, Colors.white, 0.3)!];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildNewHeader(),
            const SizedBox(height: 24),
            _buildBalanceCard(),
            const SizedBox(height: 28),
            _buildServices(),
            const SizedBox(height: 32),
            _buildRecentTransactionsHeader(),
            const SizedBox(height: 16),
            _buildCategoryFilter(),
            const SizedBox(height: 20),
            _buildTransactionsList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget buildNewHeader() {
    return Stack(
      children: [
        // Gradient Background
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorConstants.navy, ColorConstants.royalBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
        ),

        // Blurred Glass Overlay Circle
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: ColorConstants.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerAppBar(),
                const SizedBox(height: 26),
                _userInfoSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Glassmorphic app title
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: ColorConstants.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: ColorConstants.white.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(ImageConstants.logo, height: 30),
                  const SizedBox(width: 10),
                  Text(
                    "Money Map",
                    style: GoogleFonts.inter(
                      color: ColorConstants.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Notification Icon
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications_rounded,
            color: ColorConstants.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _userInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back",
          style: GoogleFonts.inter(
            color: ColorConstants.white.withOpacity(0.9),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Profile Avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.blues50,
              ),
              child: Container(
                width: 40, // control size
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child:
                      imagePath == null ||
                          imagePath!.isEmpty ||
                          !File(imagePath!).existsSync()
                      ? Icon(Icons.person, size: 28, color: ColorConstants.navy)
                      : Image.file(File(imagePath!), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, ${userName ?? '.....!'}",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  "Let’s manage your money smartly",
                  style: GoogleFonts.inter(
                    color: ColorConstants.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Highlight Box
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ColorConstants.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ColorConstants.white.withOpacity(0.3),
                ),
              ),
              child: Text(
                "Tip: Track expenses daily for better control",
                style: GoogleFonts.inter(
                  color: ColorConstants.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.navy,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Balance",
                  style: GoogleFonts.inter(
                    color: ColorConstants.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "₹${totalBalance.toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                    color: ColorConstants.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: ColorConstants.green,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "+12.5% from last month",
                      style: GoogleFonts.inter(
                        color: ColorConstants.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: ColorConstants.gold,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions ",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: ColorConstants.navy,
            ),
          ),
          _buildServicesGrid(),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 10,
        mainAxisExtent: 80,
      ),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: InkWell(
            onTap: () {
              switch (services[index]["name"]) {
                case "My Cards":
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyCards()),
                  );
                  break;
                case "Analytics":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                  break;
                case "Category":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(),
                    ),
                  );
                  break;
                case "Budget":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetScreen(),
                    ),
                  );
                  break;
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: services[index]["gradient"],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: services[index]["gradient"][0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColorConstants.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            services[index]["icon"],
                            size: 24,
                            color: ColorConstants.white,
                          ),
                        ),
                        SizedBox(width: 9),
                        Text(
                          services[index]["name"],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ColorConstants.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Recent Activity",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ColorConstants.navy,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorConstants.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  "See All",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: ColorConstants.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: ColorConstants.white,
                ),
              ],
            ),
          ),
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
                    vertical: 5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final List<dynamic> allTransactions = [...incomeList, ...expenseList];
    // Note: Sorting would be more reliable with DateTime objects.
    // This reversal shows the most recently added items first.
    final recentTransactions = allTransactions.reversed.toList();

    final filteredTransactions = selectedFilter == "All"
        ? recentTransactions
        : recentTransactions
              .where((t) => t.category == selectedFilter)
              .toList();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(ImageConstants.aboutLottie, height: 200),
              Text(
                "No Transactions Found",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
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
      itemCount: filteredTransactions.length > 5
          ? 5
          : filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        final isExpense = transaction is ExpenseModel;
        final category = _getCategoryForName(
          transaction.category,
          isExpense: isExpense,
        );
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 400 + (index * 150)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: ColorConstants.blues50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight, // Already a constant
                        colors: getGradient(
                          category.colorCode,
                          isExpense: isExpense,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ), // Already a constant
                    child: Icon(
                      getIcon(category.iconCode),
                      color: ColorConstants.white,
                      size: 26,
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
                            Text(
                              transaction.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: ColorConstants.navy,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "${isExpense ? '-' : '+'}₹${transaction.amount.abs().toStringAsFixed(0)}",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: isExpense
                                        ? ColorConstants.red
                                        : ColorConstants.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Text(
                              transaction.category,
                              style: GoogleFonts.inter(
                                color: ColorConstants.grey,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 10),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 12,
                                        color: ColorConstants.navy,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        transaction.date,
                                        style: GoogleFonts.inter(
                                          color: ColorConstants.navy,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        //    SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
