import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/constants/image_constants.dart';
import 'package:expense_tracker/features/auth/view/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;

  List data = [
    {
      "image": ImageConstants.onboarding1,
      "title": "Organize your family life",
      "des": "Manage schedules, event and activities with ease.",
    },
    {
      "image": ImageConstants.onboarding2,
      "title": "Balance your family finance",
      "des": "Track expense and income with detailed analysis.",
    },
    {
      "image": ImageConstants.onboarding3,
      "title": "Stay connected and updated",
      "des": "Chat, create lists and get the latest news for your family.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConstants.white,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "SKIP",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: ColorConstants.navy,
              ),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CarouselSlider(
            items: data.map((item) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(item['image'], height: 200),
                  const SizedBox(height: 20),
                  Text(
                    item['title'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['des'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              );
            }).toList(),
            options: CarouselOptions(
              height: 400,
              viewportFraction: 0.9,
              autoPlay: true,
              enlargeCenterPage: true,
              autoPlayInterval: const Duration(seconds: 3),
              onPageChanged: (index, reason) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          AnimatedSmoothIndicator(
            activeIndex: currentIndex,
            count: data.length,
            effect: WormEffect(
              spacing: 8.0,
              radius: 6,
              dotWidth: 8,
              dotHeight: 8, // Already a constant
              paintStyle: PaintingStyle.stroke,
              strokeWidth: 1.5,
              dotColor: ColorConstants.grey,
              activeDotColor: ColorConstants.navy,
            ),
          ),
        ],
      ),
      bottomNavigationBar: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorConstants.navy,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                "GET STARTED",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: ColorConstants.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
