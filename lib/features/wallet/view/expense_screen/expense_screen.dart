import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/database/category_db.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/core/database/card_database.dart';
import 'package:expense_tracker/features/dashboard/models/category_model.dart';
import 'package:expense_tracker/features/wallet/models/income_model.dart';
import 'package:expense_tracker/features/wallet/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<ExpenseModel> expenseList = [];
  List<IncomeModel> incomeList = [];
  List<Map<String, dynamic>> _cards = [];
  bool isLoading = true;

  String selectedFilter = "All";
  double initialBudget = 0.0;

  final db = DBHelper();

  List<CategoryModel> categoryList = [];
  CategoryModel? selectedCategoryModel;

  @override
  void initState() {
    super.initState();
    loadExpenses();
    loadCategories();
  }

  Future<void> loadExpenses() async {
    setState(() => isLoading = true);
    expenseList = await db.getExpenses();
    incomeList = await db.getAllIncome();
    initialBudget = await db.getBudget() ?? 0.0;
    final fetchedCards = await CardDatabase.instance.getCards();
    if (mounted) {
      setState(() {
        _cards = fetchedCards;
        isLoading = false;
      });
    }
  }

  Future<void> loadCategories() async {
    categoryList = await CategoryDB.instance.fetchCategories();
    setState(() {});
  }

  double get totalExpense =>
      expenseList.fold(0, (sum, item) => sum + item.amount);

  double get totalIncome =>
      incomeList.fold(0, (sum, item) => sum + item.amount);

  double get totalBalance => initialBudget + totalIncome - totalExpense;

  double get monthlyIncome => totalBalance * 0.75;

  CategoryModel _getCategoryForName(String name) {
    return categoryList.firstWhere(
      (cat) => cat.name == name,
      orElse: () => CategoryModel(
        name: 'Other',
        iconCode: Icons.payments_rounded.codePoint,
        colorCode: ColorConstants.red.value,
      ),
    );
  }

  IconData getIcon(int codePoint) {
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  Color getColor(int colorCode) {
    return Color(colorCode);
  }

  @override
  Widget build(BuildContext context) {
    List<ExpenseModel> filteredList = selectedFilter == "All"
        ? expenseList
        : expenseList.where((e) => e.category == selectedFilter).toList();

    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: isLoading ? _buildShimmerLoading() : _buildContent(filteredList),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildContent(List<ExpenseModel> filteredList) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ColorConstants.blues50),
              color: ColorConstants.blues50,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "Total Expense",
                    style: GoogleFonts.inter(
                      color: ColorConstants.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${totalExpense.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.red,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorConstants.green),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'Spendable: ',
                        style: GoogleFonts.inter(
                          color: ColorConstants.navy,
                          fontSize: 13,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '₹${monthlyIncome.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                "Categories",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.navy,
                ),
              ),
              const Spacer(),
              Text(
                "${filteredList.length} expenses",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: ColorConstants.grey,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text("All"),
                  selected: selectedFilter == "All",
                  onSelected: (_) => setState(() => selectedFilter = "All"),
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
                      selectedColor: getColor(
                        category.colorCode,
                      ).withOpacity(0.15),
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
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: expenseList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: ColorConstants.navy,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No expenses added yet",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: ColorConstants.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap the + button to add your first expense",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ColorConstants.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final category = _getCategoryForName(item.category);
                    final categoryColor = getColor(category.colorCode);

                    return Slidable(
                      key: ValueKey(item.id),
                      endActionPane: ActionPane(
                        motion: const StretchMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              _showAddExpenseSheet(
                                context,
                                expenseToEdit: item,
                              );
                            },
                            backgroundColor: ColorConstants.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            borderRadius: BorderRadius.circular(16),
                          ),
                          SlidableAction(
                            onPressed: (context) => _deleteExpense(item.id!),
                            backgroundColor: ColorConstants.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_rounded,
                            label: 'Delete',
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: ColorConstants.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: ColorConstants.black.withOpacity(.04),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              getIcon(category.iconCode),
                              color: categoryColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Wrap(
                              spacing: 10,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: categoryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "- ₹${item.amount.toStringAsFixed(2)}",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.red,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.date,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: ColorConstants.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await _showAddExpenseSheet(context, expenseToEdit: null);
        setState(() => selectedCategoryModel = null);
      },
      backgroundColor: ColorConstants.navy,
      elevation: 6,
      icon: Icon(Icons.add_rounded, color: ColorConstants.white),
      label: Text(
        "Add Expense",
        style: GoogleFonts.inter(
          color: ColorConstants.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ColorConstants.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteExpense(id);
      await loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showAddExpenseSheet(
    BuildContext context, {
    ExpenseModel? expenseToEdit,
  }) {
    final isEditing = expenseToEdit != null;
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: expenseToEdit?.title ?? '',
    );
    final amountController = TextEditingController(
      text: expenseToEdit?.amount.toString() ?? '',
    );

    DateTime tryParseDate(String date) {
      try {
        return DateFormat('dd-MM-yyyy').parse(date);
      } catch (e) {
        try {
          return DateFormat('d/M/yyyy').parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
    }

    DateTime selectedDate = isEditing
        ? tryParseDate(expenseToEdit!.date)
        : DateTime.now();

    final dateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(selectedDate),
    );

    // --- LOCAL STATE FOR THE SHEET ---
    // Moved here so they are initialized only once when the sheet is built.
    String? localSelectedCard = expenseToEdit?.card;
    if (localSelectedCard != null &&
        !_cards.any((c) => c['bank'] == localSelectedCard)) {
      localSelectedCard = null;
    }

    CategoryModel? localSelectedCategory = isEditing
        ? (categoryList.any((cat) => cat.name == expenseToEdit.category)
              ? categoryList.firstWhere(
                  (cat) => cat.name == expenseToEdit.category,
                )
              : null)
        : null;

    return showModalBottomSheet(
      backgroundColor: ColorConstants.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ColorConstants.navy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: isEditing
                                ? ColorConstants.blue
                                : ColorConstants.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? "Edit Expense" : "Add New Expense",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        labelStyle: GoogleFonts.inter(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        filled: true,
                        fillColor: ColorConstants.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a title'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: localSelectedCard,
                      decoration: InputDecoration(
                        labelText: "Select Card",
                        labelStyle: GoogleFonts.inter(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: ColorConstants.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      items: _cards.map<DropdownMenuItem<String>>((card) {
                        final cardName = card['bank'] as String?;
                        return DropdownMenuItem<String>(
                          value: cardName,
                          child: Text(cardName ?? 'Unnamed Card'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setSheetState(() => localSelectedCard = value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a card' : null,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        labelStyle: GoogleFonts.inter(),
                        prefixText: "₹ ",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        filled: true,
                        fillColor: ColorConstants.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter an amount';
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0)
                          return 'Please enter a valid amount';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Date",
                        labelStyle: GoogleFonts.inter(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: ColorConstants.white,
                        suffixIcon: const Icon(Icons.calendar_today_rounded),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setSheetState(() {
                            selectedDate = pickedDate;
                            dateController.text = DateFormat(
                              'dd-MM-yyyy',
                            ).format(pickedDate);
                          });
                        }
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please select a date'
                          : null,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<CategoryModel>(
                      value: localSelectedCategory,
                      decoration: InputDecoration(
                        labelText: "Category",
                        labelStyle: GoogleFonts.inter(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: ColorConstants.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      items: categoryList.map((category) {
                        return DropdownMenuItem<CategoryModel>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                getIcon(category.iconCode),
                                color: getColor(category.colorCode),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setSheetState(() => localSelectedCategory = value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final amount =
                                double.tryParse(amountController.text) ?? 0;
                            final model = ExpenseModel(
                              id: expenseToEdit?.id,
                              title: titleController.text,
                              amount: amount,
                              category: localSelectedCategory!.name,
                              date: DateFormat('d/M/yyyy').format(selectedDate),
                              card: localSelectedCard,
                            );

                            try {
                              if (isEditing) {
                                await db.updateExpense(model);
                                print(
                                  "Expense updated successfully: ${model.toMap()}",
                                );
                              } else {
                                await db.insertExpense(model);
                                print(
                                  "Expense inserted successfully: ${model.toMap()}",
                                );
                              }
                            } catch (e, stackTrace) {
                              print("Error saving expense: $e");
                              print(stackTrace);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error saving expense: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }

                            Navigator.pop(context);
                            await loadExpenses();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? "Save Changes" : "Add Expense",
                          style: GoogleFonts.inter(
                            color: ColorConstants.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
