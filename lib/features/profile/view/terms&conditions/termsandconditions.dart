import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditions extends StatefulWidget {
  const TermsAndConditions({super.key});

  @override
  State<TermsAndConditions> createState() => _TermsAndConditionsState();
}

class _TermsAndConditionsState extends State<TermsAndConditions>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.blues50,
      appBar: AppBar(
        backgroundColor: ColorConstants.navy,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorConstants.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Terms & Condition",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: ColorConstants.white,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [ColorConstants.navy, ColorConstants.blue700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.navy.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.handshake_outlined,
                            size: 48,
                            color: ColorConstants.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Welcome to Expense Tracker!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: ColorConstants.white,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "These Terms & Conditions govern the use of this application. By using this app, you agree to follow these terms.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: ColorConstants.white.withOpacity(0.9),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms Sections
                    _buildTermSection(
                      icon: Icons.security_outlined,
                      iconColor: ColorConstants.blue,
                      title: "1. Data Usage",
                      content:
                          "We store your expense records locally or in secure storage. We do not sell or share your data with third parties.",
                    ),

                    const SizedBox(height: 16),

                    _buildTermSection(
                      icon: Icons.person_outline_rounded,
                      iconColor: ColorConstants.green,
                      title: "2. Personal Responsibility",
                      content:
                          "All financial entries and spending decisions are your responsibility. This app acts only as a tracking tool.",
                    ),

                    const SizedBox(height: 16),

                    _buildTermSection(
                      icon: Icons.account_balance_outlined,
                      iconColor: ColorConstants.orange,
                      title: "3. No Financial Advice",
                      content:
                          "The app does not provide investment or financial advice. Users should consult professionals for financial planning.",
                    ),

                    const SizedBox(height: 16),

                    _buildTermSection(
                      icon: Icons.update_outlined,
                      iconColor: ColorConstants.purple,
                      title: "4. App Changes",
                      content:
                          "We may update features or policies anytime to improve user experience.",
                    ),

                    const SizedBox(height: 16),

                    _buildTermSection(
                      icon: Icons.support_agent_outlined,
                      iconColor: ColorConstants.teal,
                      title: "5. Contact",
                      content: "For any questions, contact our support team.",
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 32),

                    // Footer
                    Text(
                      "Last updated: November 2024",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ColorConstants.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.navy.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // Already a constant
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.2),
                      iconColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: ColorConstants.grey,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
