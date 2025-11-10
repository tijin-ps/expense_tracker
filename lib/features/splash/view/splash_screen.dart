import 'dart:async';
import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/constants/image_constants.dart';
import 'package:expense_tracker/features/auth/service/user_service.dart';
import 'package:expense_tracker/features/dashboard/view/bottom_nav_bar/bottom_nav_bar_screen.dart';
import 'package:expense_tracker/features/onboarding/view/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  UserService userService = UserService();
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<Offset> _subtitleSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Text animations (staggered)
    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _subtitleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      checkLogin();
    });
  }

  Future<void> checkLogin() async {
    if (await userService.islogin() == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoFadeAnimation,
              child: ScaleTransition(
                scale: _logoScaleAnimation,
                child: Image.asset(ImageConstants.logo, height: 160),
              ),
            ),
            const SizedBox(height: 16),
            SlideTransition(
              position: _titleSlideAnimation,
              child: FadeTransition(
                opacity: _controller,
                child: Text(
                  "MONEY MAP",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: ColorConstants.blue,
                  ),
                ),
              ),
            ),
            SlideTransition(
              position: _subtitleSlideAnimation,
              child: FadeTransition(
                opacity: _controller,
                child: Text(
                  "Navigate Your Finances. Secure Your Future",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ColorConstants.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
