import 'package:carousel_slider/carousel_slider.dart';
import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/constants/image_constants.dart';
import 'package:expense_tracker/core/database/card_database.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/core/database/category_db.dart';
import 'package:expense_tracker/features/wallet/models/expense_model.dart';
import 'package:expense_tracker/features/wallet/models/income_model.dart';
import 'package:expense_tracker/features/dashboard/models/card_model.dart';
import 'package:expense_tracker/features/dashboard/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/services.dart';

class MyCards extends StatefulWidget {
  const MyCards({super.key});

  @override
  State<MyCards> createState() => _MyCardsScreenState();
}

class UnifiedTransaction {
  final String title;
  final double amount;
  final String date;
  final String category;
  final bool isIncome;

  UnifiedTransaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isIncome,
  });
}

class _MyCardsScreenState extends State<MyCards> with TickerProviderStateMixin {
  int _currentCardIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<CardModel> _cards = [];
  List<ExpenseModel> _expenseList = [];
  List<IncomeModel> _incomeList = [];
  List<CategoryModel> _categoryList = [];
  bool _isLoading = true;
  final db = DBHelper();

  // final List<Map<String, dynamic>> _cards = [
  //   {
  //     'bank': 'Quantum Bank',
  //     'number': '**** **** **** 8014',
  //     'expiry': '12/26',
  //     'holder': 'Tijin Thomas',
  //     'balance': '₹12,450.00',
  //     'logo': ImageConstants.feedback,
  //     'gradient': [
  //       ColorConstants.cardGradientBlueLight,
  //       ColorConstants.cardGradientPurple,
  //     ],
  //     'type': 'Platinum',
  //   },
  //   {
  //     'bank': 'Stellar Bank',
  //     'number': '**** **** **** 3456',
  //     'expiry': '08/25',
  //     'holder': 'Tijin Thomas',
  //     'balance': '₹8,320.50',
  //     'logo': ImageConstants.feedback,
  //     'gradient': [
  //       ColorConstants.cardGradientPink,
  //       ColorConstants.cardGradientRed,
  //     ],
  //     'type': 'Gold',
  //   },
  //   {
  //     'bank': 'Nova Bank',
  //     'number': '**** **** **** 7892',
  //     'expiry': '03/27',
  //     'holder': 'Tijin Thomas',
  //     'balance': '₹5,670.25',
  //     'logo': ImageConstants.feedback,
  //     'gradient': [
  //       ColorConstants.cardGradientBlue,
  //       ColorConstants.cardGradientCyan,
  //     ],
  //     'type': 'Silver',
  //   },
  // ];

  // final List<Map<String, dynamic>> _transactions = [
  //   {
  //     'store': 'Apple Store',
  //     'date': 'Apr 24',
  //     'amount': -999.00, // Example: iPhone purchase
  //     'icon': Icons.phone_iphone,
  //     'color': ColorConstants.cardGradientBlueLight,
  //   },
  //   {
  //     'store': 'Amazon',
  //     'date': 'Apr 22',
  //     'amount': -45.50,
  //     'icon': Icons.shopping_cart,
  //     'color': ColorConstants.cardGradientRed,
  //   },
  //   {
  //     'store': 'Starbucks',
  //     'date': 'Apr 21',
  //     'amount': -5.25,
  //     'icon': Icons.local_cafe,
  //     'color': ColorConstants.cardGradientBlue,
  //   },
  //   {
  //     'store': 'Netflix',
  //     'date': 'Apr 20',
  //     'amount': -15.99,
  //     'icon': Icons.play_circle_outline,
  //     'color': ColorConstants.cardGradientPink,
  //   },
  // ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cardData = await CardDatabase.instance.getCards();
    _expenseList = await db.getExpenses();
    _incomeList = await db.getAllIncome();
    _categoryList = await CategoryDB.instance.fetchCategories();
    if (mounted) {
      setState(() {
        _cards = cardData.map((e) => CardModel.fromMap(e)).toList();
        _isLoading = false;
        if (_cards.isNotEmpty) {
          _fadeController.forward();
        }
      });
    }
  }

  double _getCardIncome(String cardName) {
    return _incomeList
        .where((income) => income.card == cardName)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double _getCardExpense(String cardName) {
    return _expenseList
        .where((expense) => expense.card == cardName)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double _getCardBalance(CardModel card) {
    // Remove currency symbols and commas, then parse.
    final initialBalanceString = card.balance.replaceAll(RegExp(r'[₹,]'), '');
    final initialBalance = double.tryParse(initialBalanceString) ?? 0.0;
    final income = _getCardIncome(card.bank);
    final expense = _getCardExpense(card.bank);
    return initialBalance + income - expense;
  }

  List<UnifiedTransaction> _getRecentTransactionsForCard(String cardName) {
    List<UnifiedTransaction> transactions = [];

    // Add expenses
    transactions.addAll(
      _expenseList
          .where((e) => e.card == cardName)
          .map(
            (e) => UnifiedTransaction(
              title: e.title,
              amount: e.amount,
              date: e.date,
              category: e.category,
              isIncome: false,
            ),
          ),
    );

    // Add incomes
    transactions.addAll(
      _incomeList
          .where((i) => i.card == cardName)
          .map(
            (i) => UnifiedTransaction(
              title: i.title,
              amount: i.amount,
              date: i.date,
              category: i.category,
              isIncome: true,
            ),
          ),
    );

    // Sort by date (most recent first)
    transactions.sort((a, b) {
      try {
        final dateA = DateFormat('d/M/yyyy').parse(a.date);
        final dateB = DateFormat('d/M/yyyy').parse(b.date);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return transactions;
  }

  CategoryModel _getCategoryForName(String name) {
    return _categoryList.firstWhere(
      (cat) => cat.name == name,
      orElse: () => CategoryModel(
        name: 'Other',
        iconCode: 57948,
        colorCode: Colors.grey.value,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  List<Color> _getCardGradient(String? cardType) {
    switch (cardType) {
      case 'Platinum':
        return [
          ColorConstants.cardGradientBlueLight,
          ColorConstants.cardGradientPurple,
        ];
      case 'Gold':
        return [
          ColorConstants.cardGradientPink,
          ColorConstants.cardGradientRed,
        ];
      case 'Silver':
        return [
          ColorConstants.cardGradientBlue,
          ColorConstants.cardGradientCyan,
        ];
      case 'Debit':
        return [ColorConstants.green, ColorConstants.lightGreen];
      case 'Credit':
        return [ColorConstants.orange, ColorConstants.gold];
      default:
        return [
          ColorConstants.navy,
          ColorConstants.royalBlue,
        ]; // Default gradient
    }
  }

  Color _getCardColor(String? cardType) {
    // Return the first color of the gradient as the primary color
    return _getCardGradient(cardType)[0];
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
          "My Cards",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
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
                _buildCardCarousel(),
                const SizedBox(height: 20),
                if (_cards.isNotEmpty) _buildPageIndicator(),
                const SizedBox(height: 32),
                if (_cards.isNotEmpty) _buildCardStats(),
                const SizedBox(height: 32),
                _buildRecentTransactions(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildCardCarousel() {
    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/loading1.json', height: 200),
            const SizedBox(height: 16),
            Text(
              "No cards added yet",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: ColorConstants.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the '+' button to add a card",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ColorConstants.grey,
              ),
            ),
          ],
        ),
      );
    }
    return CarouselSlider.builder(
      itemCount: _cards.length,
      itemBuilder: (context, index, realIndex) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuint,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _CreditCardWidget(
                card: _cards[index],
                cardGradient: _getCardGradient(_cards[index].type),
                onDelete: () => _confirmDeleteCard(index),
              ),
            );
          },
        );
      },
      options: CarouselOptions(
        height: 190,
        enlargeCenterPage: true,
        viewportFraction: 0.8,
        onPageChanged: (index, reason) {
          setState(() => _currentCardIndex = index);
          _fadeController.reset();
          _fadeController.forward();
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return AnimatedSmoothIndicator(
      activeIndex: _currentCardIndex,
      count: _cards.length,
      effect: ExpandingDotsEffect(
        dotHeight: 8,
        dotWidth: 8,
        activeDotColor: ColorConstants.navy,
        dotColor: ColorConstants.grey,
        expansionFactor: 4,
      ),
    );
  }

  Widget _buildCardStats() {
    final currentCard = _cards[_currentCardIndex];
    final cardIncome = _getCardIncome(currentCard.bank);
    final cardExpense = _getCardExpense(currentCard.bank);
    final currentBalance = _getCardBalance(currentCard);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorConstants.blues50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Balance',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ColorConstants.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _buildCardTypeChip(_cards[_currentCardIndex].type),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${currentBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.navy,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 5,
                children: [
                  _buildStatItem(
                    Icons.arrow_upward,
                    'Income',
                    '₹${cardIncome.toStringAsFixed(2)}',
                    ColorConstants.green,
                  ),

                  _buildStatItem(
                    Icons.arrow_downward,
                    'Expense',
                    '₹${cardExpense.toStringAsFixed(2)}',
                    ColorConstants.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String amount,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ColorConstants.grey,
                    ),
                  ),
                  Text(
                    amount,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeChip(String? cardType) {
    final Color typeColor = _getCardColor(cardType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cardType ?? 'Unknown',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: typeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final currentCard = _cards[_currentCardIndex];
    final transactions = _getRecentTransactionsForCard(currentCard.bank);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transactions.isEmpty)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Lottie.asset(
                          ImageConstants.card,
                          height: 200,
                          width: 200,
                        ),
                        Text(
                          "No transactions for this card yet.",
                          style: GoogleFonts.inter(
                            color: ColorConstants.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.navy,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionItem(transaction);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(UnifiedTransaction transaction) {
    final category = _getCategoryForName(transaction.category);
    final color = Color(category.colorCode);
    final amountColor = transaction.isIncome
        ? ColorConstants.green
        : ColorConstants.red;
    final amountPrefix = transaction.isIncome ? '+' : '-';

    String formattedDate = transaction.date;
    try {
      final parsedDate = DateFormat('d/M/yyyy').parse(transaction.date);
      formattedDate = DateFormat('MMM d').format(parsedDate);
    } catch (e) {
      // Keep original date if parsing fails
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.blues50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconData(category.iconCode, fontFamily: 'MaterialIcons'),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Already a constant
                    color: ColorConstants.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    color: ColorConstants.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix ₹${transaction.amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: ColorConstants.navy,
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          if (_cards.length >= 5) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Card Limit Reached"),
                content: const Text("You can only add up to 5 cards."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          } else {
            _showAddCardSheet(context);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(Icons.add, color: ColorConstants.white),
        label: Text(
          'Add Card',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: ColorConstants.white,
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCard(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Card"),
        content: const Text("Are you sure you want to delete this card?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await CardDatabase.instance.deleteCard(_cards[index].id!);
              setState(() {
                _cards.removeAt(index);
              });
              Navigator.pop(context);
              _loadData();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: ColorConstants.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final bankController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final holderController = TextEditingController();
    final balanceController = TextEditingController();
    String? selectedType = 'Platinum';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Card",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.navy,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: bankController,
                        decoration: _inputDecoration("Bank Name"),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a bank name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: numberController,
                        decoration: _inputDecoration("Card Number"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                        ],
                        validator: (value) => value == null || value.length < 16
                            ? 'Enter a valid 16-digit card number'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryController,
                              decoration: _inputDecoration("Expiry (MM/YY)"),
                              keyboardType: TextInputType.datetime,
                              validator: (value) =>
                                  value == null || !value.contains('/')
                                  ? 'Enter valid expiry'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: balanceController,
                              decoration: _inputDecoration("Current Balance"),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Enter balance'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: holderController,
                        decoration: _inputDecoration("Card Holder Name"),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter holder name'
                            : null,
                      ), // No description field here, as requested for removal in expense screen.
                      // The fields are now: Bank, Number, Expiry, Balance, Holder, Type.
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: _inputDecoration("Card Type"),
                        items: ['Platinum', 'Gold', 'Silver', 'Debit', 'Credit']
                            .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                        onChanged: (newValue) {
                          setSheetState(() {
                            selectedType = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              // TODO: Implement card saving logic
                              await CardDatabase.instance.addCard(
                                CardModel(
                                  bank: bankController.text,
                                  number:
                                      "**** **** **** ${numberController.text.substring(12)}",
                                  expiry: expiryController.text,
                                  holder: holderController.text,
                                  balance: "₹${balanceController.text}",
                                  type: selectedType!,
                                ).toMap(),
                              );

                              Navigator.pop(context);
                              _loadData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Save Card",
                            style: GoogleFonts.inter(
                              color: ColorConstants.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _CreditCardWidget extends StatelessWidget {
  final CardModel card;
  final List<Color> cardGradient;
  final VoidCallback onDelete;
  const _CreditCardWidget({
    required this.card, // Changed to accept CardModel
    required this.cardGradient,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16), // Reduced from 24 to 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Prevents extra vertical space
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.bank,
                            style: GoogleFonts.inter(
                              color: ColorConstants.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2), // Reduced from 4 to 2
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ColorConstants.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              card.type,
                              style: GoogleFonts.inter(
                                color: ColorConstants.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: ColorConstants.white.withOpacity(0.8),
                        ),
                        onPressed: onDelete,
                        tooltip: "Delete Card",
                      ),
                    ],
                  ),

                  const SizedBox(height: 8), // Reduced spacing

                  Text(
                    card.number,
                    style: GoogleFonts.inter(
                      color: ColorConstants.white,
                      fontSize: 14,
                      letterSpacing: 2.5, // Slightly tighter
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12), // Reduced from 16 to 12

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: GoogleFonts.inter(
                              color: ColorConstants.white.withOpacity(0.7),
                              fontSize: 9,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            card.holder,
                            style: GoogleFonts.inter(
                              color: ColorConstants.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EXPIRES',
                            style: GoogleFonts.inter(
                              color: ColorConstants.white.withOpacity(0.7),
                              fontSize: 9,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            card.expiry,
                            style: GoogleFonts.inter(
                              color: ColorConstants.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
  }
}
