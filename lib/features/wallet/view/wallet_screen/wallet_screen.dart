import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/features/wallet/view/expense_screen/expense_screen.dart';
import 'package:expense_tracker/features/wallet/view/income_screen/income_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Expense & Income
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorConstants.navy,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            "Wallet",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: ColorConstants.white,
            ),
          ),
          bottom: TabBar(
            indicatorColor: ColorConstants.white,
            labelColor: ColorConstants.white, // Already a constant
            unselectedLabelColor: ColorConstants.white.withOpacity(
              0.6,
            ), // Already a constant
            tabs: [
              Tab(
                child: Text("Expense", style: GoogleFonts.inter(fontSize: 14)),
              ),
              Tab(
                child: Text("Income", style: GoogleFonts.inter(fontSize: 14)),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: const [
            // Expense Page
            ExpenseScreen(),

            // Income Page
            IncomeScreen(),
          ],
        ),
      ),
    );
  }
}
