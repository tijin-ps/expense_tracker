import 'dart:io';
import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/features/auth/service/user_service.dart';
import 'package:expense_tracker/features/auth/view/login/login_screen.dart';
import 'package:expense_tracker/features/profile/view/edit_profile/edit_profile_screen.dart';
import 'package:expense_tracker/features/profile/view/feedback/feedback_screen.dart';
import 'package:expense_tracker/features/profile/view/terms&conditions/termsandconditions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  UserService userService = UserService();
  final DBHelper dbHelper = DBHelper();
  String? userEmail;
  String? userName;
  String? imagePath;
  bool _profileExists = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    String? email = await userService.getemail();
    String? phone = await userService.getphone();
    userEmail = email?.isNotEmpty == true ? email : phone;

    final profileData = await dbHelper.getProfile();
    if (profileData != null) {
      _profileExists = true;
      userName =
          "${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}"
              .trim();
      imagePath = profileData['image_path'];
    } else {
      _profileExists = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstants.navy,
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: ColorConstants.white,
          ),
        ),
      ),
      backgroundColor: ColorConstants.white,
      body: CustomScrollView(
        slivers: [
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Header Card
                  _buildProfileHeader(),

                  const SizedBox(height: 24),

                  // General Section
                  _buildSectionCard(
                    title: "General",
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: _profileExists
                            ? "Edit Profile"
                            : "Create Profile",
                        subtitle: "Change profile picture, number, etc.",
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          if (result == true) _loadUserData();
                        },
                        gradientColors: [
                          ColorConstants.blue400,
                          ColorConstants.blue,
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Preferences Section
                  _buildSectionCard(
                    title: "Preferences",
                    items: [
                      _MenuItem(
                        icon: Icons.feedback_outlined,
                        title: "Feedback",
                        subtitle: "Provide us with your valuable feedback",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(),
                          ),
                        ),
                        gradientColors: const [
                          ColorConstants.green, // Already a constant
                          ColorConstants.green,
                        ],
                      ),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        title: "Terms and Conditions",
                        subtitle: "Read our terms and policies",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsAndConditions(),
                          ),
                        ),
                        gradientColors: const [
                          ColorConstants.orange, // Already a constant
                          ColorConstants.orange,
                        ],
                      ),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        title: "Log Out",
                        subtitle: "Securely log out of Account",
                        onTap: () => _showLogoutDialog(),
                        gradientColors: const [
                          ColorConstants.red400,
                          ColorConstants.red, // Already a constant
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorConstants.white, ColorConstants.blues50],
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.navy.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar with gradient border
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.blues50,
                ),
                child: Container(
                  width: 90, // control size
                  height: 90,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    // Already a constant
                    child: imagePath == null || imagePath!.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: ColorConstants.navy,
                          )
                        : Image.file(File(imagePath!), fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, ${userName ?? 'Welcome!'}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.navy,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail ?? "No Email Found",
                      style: GoogleFonts.inter(
                        color: ColorConstants.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstants.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ColorConstants.green.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified, // This was const
                            size: 14,
                            color: ColorConstants.green600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Verified",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.green,
                            ),
                          ),
                        ],
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
  }

  Widget _buildSectionCard({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: ColorConstants.blues50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: ColorConstants.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  color: ColorConstants.grey.withOpacity(0.2),
                ),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMenuItem(item);
              }, // Already a constant
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        // Already a constant
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: item.gradientColors),
                borderRadius: BorderRadius.circular(12), // Already a constant
              ),
              child: Icon(item.icon, color: ColorConstants.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.navy,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ColorConstants.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: ColorConstants.grey),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10), // Already a constant
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: ColorConstants.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Log Out?",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to log out of your account?",
            style: GoogleFonts.inter(
              fontSize: 15,
              color: ColorConstants.grey,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  color: ColorConstants.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            ElevatedButton(
              // Already a constant
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.red,
                foregroundColor: ColorConstants.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await userService.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(
                "Log Out",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.gradientColors,
  });
}
