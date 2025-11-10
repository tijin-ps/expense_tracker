import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/constants/image_constants.dart';
import 'package:expense_tracker/features/auth/service/user_service.dart';
import 'package:expense_tracker/features/auth/view/otp_verification/otp_verification.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserService userService = UserService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  Future<void> _continue() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    await userService.saveusercredentials(email: email, mobile: phone);

    if (email.isNotEmpty && email.contains("@")) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerification(contact: email),
        ),
      );
    } else if (phone.length == 10) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerification(contact: phone),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid email or phone number")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Sign up",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: ColorConstants.navy,
                  ),
                ),
                Text(
                  "Get control of your finances with us",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ColorConstants.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Lottie.asset(ImageConstants.loginLottie, height: 200),
                const SizedBox(height: 20),

                /// Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Continue with Email",
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: ColorConstants.grey,
                      ), // Already a constant
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: ColorConstants.navy),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// Google Button
                InkWell(
                  onTap: () {},
                  child: Stack(
                    children: [
                      Container(
                        height: 65,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            6,
                          ), // Already a constant
                          border: Border.all(color: ColorConstants.grey),
                        ),
                        child: const Center(
                          child: Text("Continue with Google"),
                        ),
                      ),
                      Positioned(
                        top: 15,
                        left: 20,
                        child: Image.asset(
                          ImageConstants.googleLogo,
                          height: 35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      // Already a constant
                      child: Container(height: 1, color: ColorConstants.grey),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR"),
                    ), // Already a constant
                    Expanded(
                      child: Container(height: 1, color: ColorConstants.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// Phone Field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "Enter your mobile number",
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 10),
                        Text("🇮🇳  +91"),
                        SizedBox(width: 10), // Already a constant
                        VerticalDivider(color: ColorConstants.grey),
                      ],
                    ),
                    enabledBorder: OutlineInputBorder(
                      // Already a constant
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: ColorConstants.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: ColorConstants.navy),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.navy,
            minimumSize: const Size(double.infinity, 55),
          ),
          onPressed: _continue,
          child: Text(
            "Continue",
            style: TextStyle(color: ColorConstants.white),
          ),
        ),
      ),
    );
  }
}
